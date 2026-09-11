using System.Globalization;
using Microsoft.Extensions.Options;
using ModelContextProtocol;
using Sales.Mcp.Application.Configuration;

namespace Sales.Mcp.Application.Validation;

public sealed class ToolArgumentValidator
{
    private static readonly string[] SupportedGroups = ["day", "month", "year"];
    private static readonly string[] SupportedProductSorts = ["unitsSold", "netSales"];
    private static readonly string[] SupportedCustomerSorts = ["grossSales", "orderCount"];
    private static readonly string[] SupportedSalesRepSorts = ["revenue", "orderCount", "averageOrderValue", "commissionAmount"];
    private readonly QueryGuardrailsOptions _options;

    public ToolArgumentValidator(IOptions<QueryGuardrailsOptions> options)
    {
        _options = options.Value;
    }

    public DateRange ValidateDateRange(string startDate, string endDate)
    {
        if (!DateOnly.TryParseExact(startDate, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var start))
        {
            throw new McpException("startDate deve estar no formato yyyy-MM-dd.");
        }

        if (!DateOnly.TryParseExact(endDate, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var end))
        {
            throw new McpException("endDate deve estar no formato yyyy-MM-dd.");
        }

        if (end < start)
        {
            throw new McpException("endDate nao pode ser menor que startDate.");
        }

        var totalDays = end.DayNumber - start.DayNumber + 1;
        if (totalDays > _options.MaxDateRangeDays)
        {
            throw new McpException($"O intervalo maximo permitido e de {_options.MaxDateRangeDays} dias.");
        }

        return new DateRange(start, end);
    }

    public int ValidateLimit(int limit)
    {
        if (limit <= 0)
        {
            throw new McpException("limit deve ser maior que zero.");
        }

        return Math.Min(limit, _options.MaxPageSize);
    }

    public string ValidateRevenueGroupBy(string groupBy) => ValidateAllowed(groupBy, "groupBy", SupportedGroups);

    public string ValidateTopProductSortBy(string sortBy) => ValidateAllowed(sortBy, "sortBy", SupportedProductSorts);

    public string ValidateTopCustomerSortBy(string sortBy) => ValidateAllowed(sortBy, "sortBy", SupportedCustomerSorts);

    public string ValidateTopSalesRepSortBy(string sortBy) => ValidateAllowed(sortBy, "sortBy", SupportedSalesRepSorts);

    public string NormalizeCode(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new McpException("O codigo nao pode ser vazio.");
        }
        return value.Trim().ToUpperInvariant();
    }

    public string? NormalizeOptionalCode(string? value)
        => string.IsNullOrWhiteSpace(value) ? null : value.Trim().ToUpperInvariant();

    private static string ValidateAllowed(string value, string parameterName, IReadOnlyCollection<string> allowed)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new McpException($"{parameterName} e obrigatorio.");
        }

        var normalized = value.Trim();
        var match = allowed.FirstOrDefault(candidate => candidate.Equals(normalized, StringComparison.OrdinalIgnoreCase));
        if (match is null)
        {
            throw new McpException($"{parameterName} deve ser um destes valores: {string.Join(", ", allowed)}.");
        }

        return match;
    }
}

public readonly record struct DateRange(DateOnly Start, DateOnly End)
{
    public DateTime StartAtMidnight => Start.ToDateTime(TimeOnly.MinValue);

    public DateTime EndExclusive => End.AddDays(1).ToDateTime(TimeOnly.MinValue);
}
