using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;
using Sales.Mcp.Application.Abstractions;
using Sales.Mcp.Application.Configuration;
using Sales.Mcp.Application.Infrastructure;
using Sales.Mcp.Application.Services;
using Sales.Mcp.Application.Validation;
using Sales.Mcp.Server.Authentication;
using Sales.Mcp.Server.Configuration;
using Sales.Mcp.Server.Endpoints;
using Sales.Mcp.Server.Health;
using Sales.Mcp.Server.Middleware;
using Sales.Mcp.Server.Resources;
using Sales.Mcp.Server.Tools;

var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddOptions<McpOptions>()
    .Bind(builder.Configuration.GetSection("Mcp"))
    .ValidateDataAnnotations()
    .ValidateOnStart();

builder.Services
    .AddOptions<DatabaseOptions>()
    .Bind(builder.Configuration.GetSection("Database"))
    .ValidateDataAnnotations()
    .ValidateOnStart();

var mcpSectionValues = builder.Configuration.GetSection("Mcp").Get<McpOptions>() ?? new McpOptions();
builder.WebHost.ConfigureKestrel(options =>
{
    options.AddServerHeader = false;
    options.Limits.MaxRequestBodySize = mcpSectionValues.MaxRequestBodyBytes;
});

// HTTPS condicional: se um certificado for fornecido via config, habilita HTTPS
var httpsCertPath = builder.Configuration["Kestrel:Certificates:Default:Path"];
var httpsCertPassword = builder.Configuration["Kestrel:Certificates:Default:Password"];
if (!string.IsNullOrEmpty(httpsCertPath) && !string.IsNullOrEmpty(httpsCertPassword))
{
    builder.WebHost.ConfigureKestrel(options =>
    {
        options.ListenAnyIP(8443, listenOptions =>
        {
            listenOptions.UseHttps(httpsCertPath, httpsCertPassword);
        });
    });
}

// Rate Limiting para endpoints MCP
var rateLimitSection = builder.Configuration.GetSection("RateLimiting:McpEndpoint");
var permitLimit = rateLimitSection.GetValue<int>("PermitLimit", 100);
var windowInMinutes = rateLimitSection.GetValue<int>("WindowInMinutes", 1);
var queueLimit = rateLimitSection.GetValue<int>("QueueLimit", 5);

builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("McpPolicy", config =>
    {
        config.PermitLimit = permitLimit;
        config.Window = TimeSpan.FromMinutes(windowInMinutes);
        config.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        config.QueueLimit = queueLimit;
    });

    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
});

var baseReadOnlyConnectionString = builder.Configuration.GetConnectionString("ReadOnly")
    ?? throw new InvalidOperationException("ConnectionStrings__ReadOnly nao foi configurada.");
var databaseOptions = builder.Configuration.GetSection("Database").Get<DatabaseOptions>()
    ?? throw new InvalidOperationException("A secao Database nao foi configurada.");
var resolvedReadOnlyConnectionString = ConnectionStringSecretResolver.Resolve(
    baseReadOnlyConnectionString,
    databaseOptions.ReadOnlyPasswordFile);

builder.Services.Configure<DatabaseConnectionOptions>(options =>
{
    options.ReadOnlyConnectionString = resolvedReadOnlyConnectionString;
});

builder.Services.Configure<QueryGuardrailsOptions>(options =>
{
    options.MaxPageSize = mcpSectionValues.MaxPageSize;
});

builder.Services.AddSingleton<ISqlConnectionFactory, SqlServerConnectionFactory>();
builder.Services.AddSingleton<ToolArgumentValidator>();
builder.Services.AddSingleton<SalesAnalyticsService>();
builder.Services.AddSingleton<SalesSchemaService>();
builder.Services.AddSingleton<FileTokenProvider>();
builder.Services.AddSingleton(sp => new ReadinessProbe(
    resolvedReadOnlyConnectionString,
    sp.GetRequiredService<FileTokenProvider>()));

builder.Services
    .AddAuthentication("Bearer")
    .AddScheme<AuthenticationSchemeOptions, FileBearerAuthenticationHandler>("Bearer", _ => { });

builder.Services.AddAuthorizationBuilder()
    .SetFallbackPolicy(new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build());

builder.Services.AddMcpServer()
    .WithHttpTransport(options =>
    {
        options.Stateless = true;
        // EnableLegacySse is obsolete, using Streamable HTTP instead
    })
    .WithTools<SalesTools>()
    .WithResources<SalesResources>()
    .AddAuthorizationFilters();

var app = builder.Build();

app.UseMiddleware<CorrelationIdMiddleware>();
app.UseMiddleware<OriginValidationMiddleware>();
app.UseMiddleware<McpRequestGuardMiddleware>();

app.UseRateLimiter();

app.UseAuthentication();
app.UseAuthorization();

app.MapDiagnosticEndpoints();
app.MapMcp("/mcp").RequireAuthorization().RequireRateLimiting("McpPolicy");

app.Run();

public partial class Program;
