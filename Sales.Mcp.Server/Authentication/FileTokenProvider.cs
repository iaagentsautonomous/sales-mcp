using Microsoft.Extensions.Options;
using Sales.Mcp.Server.Configuration;

namespace Sales.Mcp.Server.Authentication;

public sealed class FileTokenProvider
{
    private readonly string _tokenFile;
    private readonly object _sync = new();
    private DateTime _lastWriteUtc;
    private string? _cachedToken;

    public FileTokenProvider(IOptions<McpOptions> options)
    {
        _tokenFile = options.Value.BearerTokenFile;
    }

    public string GetRequiredToken()
    {
        lock (_sync)
        {
            var info = new FileInfo(_tokenFile);
            if (!info.Exists)
            {
                throw new InvalidOperationException($"O arquivo de token MCP '{_tokenFile}' nao existe.");
            }

            if (_cachedToken is not null && info.LastWriteTimeUtc == _lastWriteUtc)
            {
                return _cachedToken;
            }

            var token = File.ReadAllText(_tokenFile).Trim();
            if (string.IsNullOrWhiteSpace(token))
            {
                throw new InvalidOperationException($"O arquivo de token MCP '{_tokenFile}' esta vazio.");
            }

            _cachedToken = token;
            _lastWriteUtc = info.LastWriteTimeUtc;
            return token;
        }
    }
}
