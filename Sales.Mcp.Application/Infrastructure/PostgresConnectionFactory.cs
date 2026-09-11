using Microsoft.Extensions.Options;
using Npgsql;
using Sales.Mcp.Application.Abstractions;
using Sales.Mcp.Application.Configuration;

namespace Sales.Mcp.Application.Infrastructure;

public sealed class PostgresConnectionFactory : ISqlConnectionFactory
{
    private readonly string _connectionString;

    public PostgresConnectionFactory(IOptions<DatabaseConnectionOptions> options)
    {
        _connectionString = options.Value.ReadOnlyConnectionString;

        if (string.IsNullOrWhiteSpace(_connectionString))
        {
            throw new InvalidOperationException("A connection string de leitura nao foi configurada.");
        }
    }

    public async Task<NpgsqlConnection> OpenConnectionAsync(CancellationToken cancellationToken)
    {
        var connection = new NpgsqlConnection(_connectionString);
        await connection.OpenAsync(cancellationToken);
        return connection;
    }
}