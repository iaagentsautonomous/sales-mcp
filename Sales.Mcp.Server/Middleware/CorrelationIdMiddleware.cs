namespace Sales.Mcp.Server.Middleware;

public sealed class CorrelationIdMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<CorrelationIdMiddleware> _logger;

    public CorrelationIdMiddleware(RequestDelegate next, ILogger<CorrelationIdMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        context.Response.Headers["X-Correlation-Id"] = context.TraceIdentifier;

        using (_logger.BeginScope(new Dictionary<string, object?> { ["TraceId"] = context.TraceIdentifier }))
        {
            await _next(context);
        }
    }
}
