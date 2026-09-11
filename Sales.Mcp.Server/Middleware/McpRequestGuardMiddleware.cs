using Microsoft.Extensions.Options;
using Sales.Mcp.Server.Configuration;

namespace Sales.Mcp.Server.Middleware;

public sealed class McpRequestGuardMiddleware
{
    private readonly RequestDelegate _next;
    private readonly McpOptions _options;
    private readonly ILogger<McpRequestGuardMiddleware> _logger;

    public McpRequestGuardMiddleware(RequestDelegate next, IOptions<McpOptions> options, ILogger<McpRequestGuardMiddleware> logger)
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

        if (context.Request.ContentLength is > 0 && context.Request.ContentLength > _options.MaxRequestBodyBytes)
        {
            context.Response.StatusCode = StatusCodes.Status413PayloadTooLarge;
            await context.Response.WriteAsJsonAsync(new { error = "Payload acima do limite permitido." });
            return;
        }

        var nextTask = _next(context);
        var timeoutTask = Task.Delay(TimeSpan.FromSeconds(_options.RequestTimeoutSeconds), context.RequestAborted);
        var completedTask = await Task.WhenAny(nextTask, timeoutTask);

        if (completedTask == nextTask)
        {
            await nextTask;
            return;
        }

        _logger.LogWarning("Tempo limite excedido para request MCP. TraceId={TraceId}", context.TraceIdentifier);
        if (!context.Response.HasStarted)
        {
            context.Response.StatusCode = StatusCodes.Status408RequestTimeout;
            await context.Response.WriteAsJsonAsync(new { error = "Tempo limite excedido para a requisicao MCP." });
        }

        context.Abort();
    }
}
