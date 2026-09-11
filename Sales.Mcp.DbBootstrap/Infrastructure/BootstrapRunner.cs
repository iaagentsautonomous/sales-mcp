using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Sales.Mcp.DbBootstrap.Configuration;

namespace Sales.Mcp.DbBootstrap.Infrastructure;

public sealed class BootstrapRunner
{
    private static readonly Regex SafeNameRegex = new("^[A-Za-z_][A-Za-z0-9_]*$", RegexOptions.Compiled);
    private readonly BootstrapOptions _options;
    private readonly ILogger<BootstrapRunner> _logger;

    public BootstrapRunner(IOptions<BootstrapOptions> options, ILogger<BootstrapRunner> logger)
    {
        _options = options.Value;
        _logger = logger;
    }

    public async Task RunAsync(CancellationToken cancellationToken)
    {
        ValidateOptions();

        var adminConnectionString = ConnectionStringSecretResolver.Resolve(_options.AdminConnectionString, _options.AdminPasswordFile);
        var readerPassword = File.ReadAllText(_options.ReaderPasswordFile).Trim();
        if (string.IsNullOrWhiteSpace(readerPassword))
        {
            throw new InvalidOperationException($"O arquivo de secret '{_options.ReaderPasswordFile}' esta vazio.");
        }

        await WaitForSqlServerAsync(adminConnectionString, cancellationToken);
        await EnsureDatabaseAsync(adminConnectionString, cancellationToken);
        await EnsureReaderLoginAsync(adminConnectionString, readerPassword, cancellationToken);

        var databaseConnectionString = new SqlConnectionStringBuilder(adminConnectionString)
        {
            InitialCatalog = _options.DatabaseName
        }.ConnectionString;

        await EnsureReaderUserAsync(databaseConnectionString, cancellationToken);
        await ExecuteScriptsAsync(databaseConnectionString, cancellationToken);
    }

    private async Task WaitForSqlServerAsync(string adminConnectionString, CancellationToken cancellationToken)
    {
        for (var attempt = 1; attempt <= _options.MaxConnectionAttempts; attempt++)
        {
            try
            {
                await using var connection = new SqlConnection(adminConnectionString);
                await connection.OpenAsync(cancellationToken);
                _logger.LogInformation("SQL Server pronto na tentativa {Attempt}.", attempt);
                return;
            }
            catch (Exception ex) when (attempt < _options.MaxConnectionAttempts)
            {
                _logger.LogWarning(ex, "Aguardando SQL Server. Tentativa {Attempt}/{MaxAttempts}.", attempt, _options.MaxConnectionAttempts);
                await Task.Delay(TimeSpan.FromSeconds(_options.RetryDelaySeconds), cancellationToken);
            }
        }

        throw new InvalidOperationException("Nao foi possivel conectar ao SQL Server no tempo esperado.");
    }

    private async Task EnsureDatabaseAsync(string adminConnectionString, CancellationToken cancellationToken)
    {
        var safeDatabaseName = EscapeSqlIdentifier(_options.DatabaseName);
        await using var connection = new SqlConnection(adminConnectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText = $"""
            IF DB_ID(N'{_options.DatabaseName.Replace("'", "''")}') IS NULL
            BEGIN
                EXEC('CREATE DATABASE [{safeDatabaseName}]');
            END
            """;
        await command.ExecuteNonQueryAsync(cancellationToken);
        _logger.LogInformation("Banco {DatabaseName} garantido.", _options.DatabaseName);
    }

    private async Task EnsureReaderLoginAsync(string adminConnectionString, string readerPassword, CancellationToken cancellationToken)
    {
        var safeLogin = EscapeSqlIdentifier(_options.ReaderLogin);
        var escapedPassword = readerPassword.Replace("'", "''");

        await using var connection = new SqlConnection(adminConnectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandTimeout = 300;
        command.CommandText = $"""
            DECLARE @sql nvarchar(max);
            IF EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'{_options.ReaderLogin.Replace("'", "''")}')
            BEGIN
                SET @sql = N'ALTER LOGIN [{safeLogin}] WITH PASSWORD = N''{escapedPassword}'';';
            END
            ELSE
            BEGIN
                SET @sql = N'CREATE LOGIN [{safeLogin}] WITH PASSWORD = N''{escapedPassword}'';';
            END
            EXEC sp_executesql @sql;
            """;
        await command.ExecuteNonQueryAsync(cancellationToken);
        _logger.LogInformation("Login {ReaderLogin} garantido.", _options.ReaderLogin);
    }

    private async Task EnsureReaderUserAsync(string databaseConnectionString, CancellationToken cancellationToken)
    {
        var safeLogin = EscapeSqlIdentifier(_options.ReaderLogin);

        await using var connection = new SqlConnection(databaseConnectionString);
        await connection.OpenAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText = $"""
            IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'{_options.ReaderLogin.Replace("'", "''")}')
            BEGIN
                EXEC('CREATE USER [{safeLogin}] FOR LOGIN [{safeLogin}]');
            END

            IF NOT EXISTS
            (
                SELECT 1
                FROM sys.database_role_members drm
                INNER JOIN sys.database_principals rolep ON rolep.principal_id = drm.role_principal_id
                INNER JOIN sys.database_principals userp ON userp.principal_id = drm.member_principal_id
                WHERE rolep.name = 'db_datareader'
                  AND userp.name = N'{_options.ReaderLogin.Replace("'", "''")}'
            )
            BEGIN
                EXEC('ALTER ROLE [db_datareader] ADD MEMBER [{safeLogin}]');
            END

            GRANT CONNECT TO [{safeLogin}];
            """;
        await command.ExecuteNonQueryAsync(cancellationToken);
        _logger.LogInformation("Usuario {ReaderLogin} garantido em {DatabaseName}.", _options.ReaderLogin, _options.DatabaseName);
    }

    private async Task ExecuteScriptsAsync(string databaseConnectionString, CancellationToken cancellationToken)
    {
        var files = Directory
            .EnumerateFiles(_options.ScriptsPath, "*.sql", SearchOption.TopDirectoryOnly)
            .OrderBy(path => path, StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (files.Count == 0)
        {
            throw new InvalidOperationException($"Nenhum script SQL foi encontrado em '{_options.ScriptsPath}'.");
        }

        var scriptsToRun = _options.Mode.Equals("schema-only", StringComparison.OrdinalIgnoreCase)
            ? files.Where(path => Path.GetFileName(path).StartsWith("01_", StringComparison.OrdinalIgnoreCase)).ToList()
            : files;

        await using var connection = new SqlConnection(databaseConnectionString);
        await connection.OpenAsync(cancellationToken);

        foreach (var path in scriptsToRun)
        {
            _logger.LogInformation("Executando script {Script}.", Path.GetFileName(path));
            var script = await File.ReadAllTextAsync(path, cancellationToken);
            var batches = SqlScriptBatchSplitter.Split(script);

            foreach (var batch in batches)
            {
                await using var command = connection.CreateCommand();
                command.CommandTimeout = 300;
                command.CommandText = batch;
                await command.ExecuteNonQueryAsync(cancellationToken);
            }
        }

        if (_options.Mode.Equals("schema-only", StringComparison.OrdinalIgnoreCase))
        {
            await using var validationCommand = connection.CreateCommand();
            validationCommand.CommandText = """
                IF SCHEMA_ID(N'sales') IS NULL
                    THROW 50050, 'Schema sales nao encontrado apos bootstrap.', 1;

                IF (SELECT COUNT(*) FROM sys.tables AS t INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id WHERE s.name = 'sales') = 0
                    THROW 50051, 'Nenhuma tabela foi criada no schema sales.', 1;
                """;
            await validationCommand.ExecuteNonQueryAsync(cancellationToken);
        }

        _logger.LogInformation("Bootstrap concluido em modo {Mode}.", _options.Mode);
    }

    private void ValidateOptions()
    {
        if (!SafeNameRegex.IsMatch(_options.DatabaseName))
        {
            throw new InvalidOperationException("Bootstrap__DatabaseName contem caracteres nao permitidos.");
        }

        if (!SafeNameRegex.IsMatch(_options.ReaderLogin))
        {
            throw new InvalidOperationException("Bootstrap__ReaderLogin contem caracteres nao permitidos.");
        }

        if (!File.Exists(_options.AdminPasswordFile))
        {
            throw new FileNotFoundException("Arquivo de secret do SA nao encontrado.", _options.AdminPasswordFile);
        }

        if (!File.Exists(_options.ReaderPasswordFile))
        {
            throw new FileNotFoundException("Arquivo de secret do leitor nao encontrado.", _options.ReaderPasswordFile);
        }

        if (!Directory.Exists(_options.ScriptsPath))
        {
            throw new DirectoryNotFoundException($"Diretorio de scripts nao encontrado: {_options.ScriptsPath}");
        }

        if (!_options.Mode.Equals("demo", StringComparison.OrdinalIgnoreCase) &&
            !_options.Mode.Equals("schema-only", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Bootstrap__Mode deve ser 'demo' ou 'schema-only'.");
        }
    }

    private static string EscapeSqlIdentifier(string value) => value.Replace("]", "]]");
}
