using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Sales.Mcp.DbBootstrap.Configuration;
using Sales.Mcp.DbBootstrap.Infrastructure;

var builder = Host.CreateApplicationBuilder(args);

builder.Services
    .AddOptions<BootstrapOptions>()
    .Bind(builder.Configuration.GetSection("Bootstrap"))
    .ValidateOnStart();

builder.Services.AddSingleton<BootstrapRunner>();

var host = builder.Build();
var runner = host.Services.GetRequiredService<BootstrapRunner>();
await runner.RunAsync(CancellationToken.None);
