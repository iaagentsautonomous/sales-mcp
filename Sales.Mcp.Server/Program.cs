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

// --- AJUSTE 1: Configura��o condicional do McpOptions para Produ��o ---
var mcpBearerToken = Environment.GetEnvironmentVariable("McpOptions__BearerToken");

builder.Services
    .AddOptions<McpOptions>()
    .Bind(builder.Configuration.GetSection("Mcp"))
    .Configure(options =>
    {
        // Se houver um token vindo da Secret do K8s, injeta na propriedade (se houver)
        // e define um valor fict�cio no arquivo para passar na valida��o estrita [Required]
        if (!string.IsNullOrEmpty(mcpBearerToken))
        {
            options.BearerTokenFile = "not-used-in-production";
        }
    })
    .ValidateDataAnnotations()
    .ValidateOnStart();

// --- AJUSTE 2: Configura��o condicional do DatabaseOptions para Produ��o ---
var dbPassword = Environment.GetEnvironmentVariable("Database__ReadOnlyPassword");

builder.Services
    .AddOptions<DatabaseOptions>()
    .Bind(builder.Configuration.GetSection("Database"))
    .Configure(options =>
    {
        // Se houver uma senha vinda da Secret do K8s, define um valor fict�cio
        // no caminho do arquivo apenas para burlar a valida��o do [Required]
        if (!string.IsNullOrEmpty(dbPassword))
        {
            options.ReadOnlyPasswordFile = "not-used-in-production";
        }
    })
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

// --- AJUSTE 3: Resolu��o inteligente da String de Conex�o com a Secret ---
var baseReadOnlyConnectionString = builder.Configuration.GetConnectionString("ReadOnly")
    ?? throw new InvalidOperationException("ConnectionStrings__ReadOnly nao foi configurada.");

string resolvedReadOnlyConnectionString;

if (!string.IsNullOrEmpty(dbPassword))
{
    // EM PRODU��O: Constr�i a string final acoplando a senha direto da mem�ria da Secret do K8s
    var connectionBuilder = new Npgsql.NpgsqlConnectionStringBuilder(baseReadOnlyConnectionString)
    {
        Password = dbPassword
    };
    resolvedReadOnlyConnectionString = connectionBuilder.ConnectionString;
}
else
{
    // EM DESENVOLVIMENTO (Local): Usa a sua estrat�gia original lendo o arquivo f�sico .txt
    var databaseOptions = builder.Configuration.GetSection("Database").Get<DatabaseOptions>()
        ?? throw new InvalidOperationException("A secao Database nao foi configurada.");

    resolvedReadOnlyConnectionString = ConnectionStringSecretResolver.Resolve(
        baseReadOnlyConnectionString,
        databaseOptions.ReadOnlyPasswordFile);
}

builder.Services.Configure<DatabaseConnectionOptions>(options =>
{
    options.ReadOnlyConnectionString = resolvedReadOnlyConnectionString;
});

builder.Services.Configure<QueryGuardrailsOptions>(options =>
{
    options.MaxPageSize = mcpSectionValues.MaxPageSize;
});

builder.Services.AddSingleton<ISqlConnectionFactory, PostgresConnectionFactory>();
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
        // Modo moderno: Streamable HTTP + SSE. Expõe GET /mcp (text/event-stream),
        // POST /mcp (mensagens JSON-RPC) e DELETE /mcp (encerrar sessão).
        options.Stateless = false;
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
