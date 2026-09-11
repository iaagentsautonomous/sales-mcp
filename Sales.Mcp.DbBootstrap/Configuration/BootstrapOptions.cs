using System.ComponentModel.DataAnnotations;

namespace Sales.Mcp.DbBootstrap.Configuration;

public sealed class BootstrapOptions
{
    [Required]
    public string Mode { get; set; } = "demo";

    [Required]
    public string AdminConnectionString { get; set; } = string.Empty;

    [Required]
    public string AdminPasswordFile { get; set; } = string.Empty;

    [Required]
    public string ReaderLogin { get; set; } = "mcp_reader";

    [Required]
    public string ReaderPasswordFile { get; set; } = string.Empty;

    [Required]
    public string DatabaseName { get; set; } = "A2A";

    [Required]
    public string ScriptsPath { get; set; } = string.Empty;

    [Range(1, 120)]
    public int MaxConnectionAttempts { get; set; } = 60;

    [Range(1, 30)]
    public int RetryDelaySeconds { get; set; } = 5;
}
