using Microsoft.Extensions.Options;
using ModelContextProtocol;
using Sales.Mcp.Application.Configuration;
using Sales.Mcp.Application.Validation;

namespace Sales.Mcp.Tests.Validation;

public sealed class ToolArgumentValidatorTests
{
    private static readonly ToolArgumentValidator Validator = new(Options.Create(new QueryGuardrailsOptions
    {
        MaxDateRangeDays = 365,
        MaxPageSize = 50
    }));

    [Fact]
    public void ValidateDateRange_ReturnsParsedRange()
    {
        var result = Validator.ValidateDateRange("2025-01-01", "2025-01-31");

        Assert.Equal(new DateOnly(2025, 1, 1), result.Start);
        Assert.Equal(new DateOnly(2025, 1, 31), result.End);
    }

    [Fact]
    public void ValidateDateRange_ThrowsForInvalidDate()
    {
        var exception = Assert.Throws<McpException>(() => Validator.ValidateDateRange("2025-13-01", "2025-01-31"));

        Assert.Contains("startDate", exception.Message);
    }

    [Fact]
    public void ValidateLimit_ClampsToConfiguredMaximum()
    {
        var limit = Validator.ValidateLimit(999);

        Assert.Equal(50, limit);
    }
}
