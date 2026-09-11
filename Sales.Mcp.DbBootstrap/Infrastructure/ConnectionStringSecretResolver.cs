using Microsoft.Data.SqlClient;

namespace Sales.Mcp.DbBootstrap.Infrastructure;

public static class ConnectionStringSecretResolver
{
    public static string Resolve(string baseConnectionString, string passwordFile)
    {
        var builder = new SqlConnectionStringBuilder(baseConnectionString);
        if (string.IsNullOrWhiteSpace(builder.Password))
        {
            builder.Password = File.ReadAllText(passwordFile).Trim();
        }

        return builder.ConnectionString;
    }
}
