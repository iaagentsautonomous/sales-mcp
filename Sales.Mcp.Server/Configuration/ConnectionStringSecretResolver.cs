using Npgsql;

namespace Sales.Mcp.Server.Configuration;

public static class ConnectionStringSecretResolver
{
    public static string Resolve(string baseConnectionString, string passwordFile)
    {
        if (string.IsNullOrWhiteSpace(baseConnectionString))
        {
            throw new InvalidOperationException("A connection string base nao foi configurada.");
        }

        var builder = new NpgsqlConnectionStringBuilder(baseConnectionString);
        if (!string.IsNullOrWhiteSpace(builder.Password))
        {
            return builder.ConnectionString;
        }

        var password = File.ReadAllText(passwordFile).Trim();
        if (string.IsNullOrWhiteSpace(password))
        {
            throw new InvalidOperationException($"O arquivo de password '{passwordFile}' esta vazio.");
        }

        builder.Password = password;
        return builder.ConnectionString;
    }
}
