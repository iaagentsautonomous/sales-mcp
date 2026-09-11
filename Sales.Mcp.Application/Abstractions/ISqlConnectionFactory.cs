using Npgsql;

namespace Sales.Mcp.Application.Abstractions;

public interface ISqlConnectionFactory
{
    Task<NpgsqlConnection> OpenConnectionAsync(CancellationToken cancellationToken);
}
