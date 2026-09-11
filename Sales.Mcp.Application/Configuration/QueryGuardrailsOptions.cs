namespace Sales.Mcp.Application.Configuration;

public sealed class QueryGuardrailsOptions
{
    public int MaxPageSize { get; set; } = 100;

    public int MaxDateRangeDays { get; set; } = 730;
}
