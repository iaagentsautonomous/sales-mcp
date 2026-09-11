using Sales.Mcp.Server.Middleware;

namespace Sales.Mcp.Tests.Server;

public sealed class AllowedOriginEvaluatorTests
{
    [Fact]
    public void IsAllowed_ReturnsTrueForConfiguredOrigin()
    {
        var allowed = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "http://localhost:6274"
        };

        var result = AllowedOriginEvaluator.IsAllowed("http://localhost:6274", allowed);

        Assert.True(result);
    }

    [Fact]
    public void IsAllowed_ReturnsFalseForUnexpectedOrigin()
    {
        var allowed = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "http://localhost:6274"
        };

        var result = AllowedOriginEvaluator.IsAllowed("http://evil.local:8080", allowed);

        Assert.False(result);
    }
}
