using Microsoft.Data.SqlClient;

namespace Sales.Mcp.Application.Abstractions;

public interface ISqlConnectionFactory
{
    Task<SqlConnection> OpenConnectionAsync(CancellationToken cancellationToken);
}
