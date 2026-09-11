using System.ComponentModel.DataAnnotations;

namespace Sales.Mcp.Server.Configuration;

public sealed class DatabaseOptions
{
    [Required]
    public string ReadOnlyPasswordFile { get; set; } = string.Empty;
}
