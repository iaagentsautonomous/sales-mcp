using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Options;
using Sales.Mcp.Application.Abstractions;
using Sales.Mcp.Application.Configuration;

namespace Sales.Mcp.Application.Infrastructure;

public sealed class SqlServerConnectionFactory : ISqlConnectionFactory
{
    private readonly string _connectionString;

    public SqlServerConnectionFactory(IOptions<DatabaseConnectionOptions> options)
    {
        _connectionString = options.Value.ReadOnlyConnectionString;

        if (string.IsNullOrWhiteSpace(_connectionString))
        {
            throw new InvalidOperationException("A connection string de leitura nao foi configurada.");
        }
    }

    public async Task<SqlConnection> OpenConnectionAsync(CancellationToken cancellationToken)
    {
        var connection = new SqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);
        return connection;
    }
}
