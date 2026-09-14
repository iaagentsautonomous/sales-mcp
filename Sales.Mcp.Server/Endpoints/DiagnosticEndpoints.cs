using Microsoft.AspNetCore.Authorization;
using Sales.Mcp.Server.Health;

namespace Sales.Mcp.Server.Endpoints;

/// <summary>
/// Static class
/// </summary>
public static class DiagnosticEndpoints
{
    public static IEndpointRouteBuilder MapDiagnosticEndpoints(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapGet("/health/live", [AllowAnonymous] () => Results.Ok(new
        {
            status = "live",
            timestampUtc = DateTime.UtcNow
        }));

        endpoints.MapGet("/health/ready", [AllowAnonymous] async (ReadinessProbe readinessProbe, CancellationToken cancellationToken) =>
        {
            var result = await readinessProbe.CheckAsync(cancellationToken);
            return result.IsReady
                ? Results.Ok(new { status = result.Message, timestampUtc = DateTime.UtcNow })
                : Results.Problem(statusCode: StatusCodes.Status503ServiceUnavailable, title: "Service unavailable", detail: result.Message);
        });

        endpoints.MapGet("/version", () =>
        {
            var assembly = typeof(Program).Assembly.GetName();
            return Results.Ok(new
            {
                service = assembly.Name,
                version = assembly.Version?.ToString() ?? "unknown",
                framework = ".NET 8"
            });
        });

        return endpoints;
    }
}
