using System.ComponentModel;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Options;
using ModelContextProtocol.Server;
using Sales.Mcp.Application.Services;
using Sales.Mcp.Server.Configuration;

namespace Sales.Mcp.Server.Resources;

public class SalesResources
{
    private readonly SalesSchemaService _schemaService;
    private readonly IOptions<McpOptions> _optionsAccessor;

    public SalesResources(SalesSchemaService schemaService, IOptions<McpOptions> optionsAccessor)
    {
        _schemaService = schemaService;
        _optionsAccessor = optionsAccessor;
    }

    [McpServerResource(Name = "schema_overview", Title = "Schema overview", UriTemplate = "sales://schema/overview", MimeType = "application/json")]
    [Description("Retorna um resumo do schema sales no banco de dados configurado.")]
    [Authorize]
    public Task<string> GetSchemaOverviewAsync(CancellationToken cancellationToken)
        => _schemaService.GetSchemaOverviewJsonAsync(cancellationToken);

    [McpServerResource(Name = "schema_tables", Title = "Schema tables", UriTemplate = "sales://schema/tables", MimeType = "application/json")]
    [Description("Retorna as tabelas e colunas do schema sales.")]
    [Authorize]
    public Task<string> GetSchemaTablesAsync(CancellationToken cancellationToken)
        => _schemaService.GetSchemaTablesJsonAsync(cancellationToken);

    [McpServerResource(Name = "kpis_catalog", Title = "KPI catalog", UriTemplate = "sales://kpis/catalog", MimeType = "application/json")]
    [Description("Retorna o catalogo das consultas KPI disponiveis no servidor MCP.")]
    [Authorize]
    public string GetKpiCatalog() =>
        """
        {
          "kpis": [
            "get_revenue_by_period",
            "get_top_products",
            "get_top_customers",
            "get_sales_by_channel",
            "get_order_status_summary",
            "get_recent_orders"
          ],
          "notes": [
            "Todas as consultas sao somente leitura.",
            "Datas devem estar no formato yyyy-MM-dd.",
            "Os limites sao protegidos por guardrails configuraveis."
          ]
        }
        """;

    [McpServerResource(Name = "about_server", Title = "About server", UriTemplate = "sales://about/server", MimeType = "application/json")]
    [Description("Retorna metadados do servidor MCP, incluindo transporte e guardrails.")]
    [Authorize]
    public string GetAboutServer()
    {
        var options = _optionsAccessor.Value;

        return
        $$"""
        {
          "service": "sales-mcp",
          "transport": "streamable-http",
          "stateless": true,
          "security": {
            "auth": "bearer-token",
            "allowedOriginsConfigured": {{options.AllowedOriginSet.Count}},
            "requestTimeoutSeconds": {{options.RequestTimeoutSeconds}},
            "maxPageSize": {{options.MaxPageSize}},
            "maxRequestBodyBytes": {{options.MaxRequestBodyBytes}}
          }
        }
        """;
    }
}
