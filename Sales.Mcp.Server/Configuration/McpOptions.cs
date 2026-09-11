using System.ComponentModel.DataAnnotations;

namespace Sales.Mcp.Server.Configuration;

public sealed class McpOptions
{
    [Required]
    public string BearerTokenFile { get; set; } = string.Empty;

    public string AllowedOrigins { get; set; } = string.Empty;

    [Range(5, 300)]
    public int RequestTimeoutSeconds { get; set; } = 30;

    [Range(1, 1000)]
    public int MaxPageSize { get; set; } = 100;

    [Range(8192, 1048576)]
    public long MaxRequestBodyBytes { get; set; } = 131072;

    public IReadOnlySet<string> AllowedOriginSet =>
        AllowedOrigins
            .Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries)
            .Select(origin => origin.TrimEnd('/'))
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
}
