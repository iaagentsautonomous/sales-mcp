using Microsoft.Extensions.Options;
using Sales.Mcp.Server.Configuration;

namespace Sales.Mcp.Server.Middleware;

public sealed class OriginValidationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly McpOptions _options;
    private readonly ILogger<OriginValidationMiddleware> _logger;

    public OriginValidationMiddleware(RequestDelegate next, IOptions<McpOptions> options, ILogger<OriginValidationMiddleware> logger)
    {
        _next = next;
        _options = options.Value;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (!context.Request.Path.StartsWithSegments("/mcp", StringComparison.OrdinalIgnoreCase))
        {
            await _next(context);
            return;
        }

        if (!context.Request.Headers.TryGetValue("Origin", out var originValues))
        {
            await _next(context);
            return;
        }

        var origin = originValues.ToString();
        if (AllowedOriginEvaluator.IsAllowed(origin, _options.AllowedOriginSet))
        {
            await _next(context);
            return;
        }

        _logger.LogDebug("Origem bloqueada. Origin={Origin} TraceId={TraceId}", origin, context.TraceIdentifier);
        context.Response.StatusCode = StatusCodes.Status403Forbidden;
        await context.Response.WriteAsJsonAsync(new { error = "Origin nao permitida." });
    }
}
