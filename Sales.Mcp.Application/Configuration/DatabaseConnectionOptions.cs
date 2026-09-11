namespace Sales.Mcp.Application.Configuration;

public sealed class DatabaseConnectionOptions
{
    public string ReadOnlyConnectionString { get; set; } = string.Empty;
}
