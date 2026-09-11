using Npgsql;
using Sales.Mcp.Server.Authentication;

namespace Sales.Mcp.Server.Health;

public sealed class ReadinessProbe
{
    private readonly string _connectionString;
    private readonly FileTokenProvider _tokenProvider;

    public ReadinessProbe(string connectionString, FileTokenProvider tokenProvider)
    {
        _connectionString = connectionString;
        _tokenProvider = tokenProvider;
    }

    public async Task<(bool IsReady, string Message)> CheckAsync(CancellationToken cancellationToken)
    {
        try
        {
            _ = _tokenProvider.GetRequiredToken();

            await using var connection = new NpgsqlConnection(_connectionString);
            await connection.OpenAsync(cancellationToken);
            await using var command = connection.CreateCommand();
            command.CommandText = "SELECT 1";
            await command.ExecuteScalarAsync(cancellationToken);

            return (true, "ready");
        }
        catch (Exception ex)
        {
            return (false, ex.Message);
        }
    }
}
