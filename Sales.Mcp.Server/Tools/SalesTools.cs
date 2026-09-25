using System.ComponentModel;
using Microsoft.AspNetCore.Authorization;
using ModelContextProtocol.Server;
using Sales.Mcp.Application.Dtos;
using Sales.Mcp.Application.Services;

namespace Sales.Mcp.Server.Tools;

public class SalesTools
{
    private readonly SalesAnalyticsService _analyticsService;

    public SalesTools(SalesAnalyticsService analyticsService)
    {
        _analyticsService = analyticsService;
    }

    [McpServerTool(Name = "get_revenue_by_period", Title = "Revenue by period")]
    [Description("Retorna faturamento bruto e reembolsado por dia, mes ou ano dentro de um intervalo.")]
    [Authorize]
    public Task<RevenueByPeriodResultDto> GetRevenueByPeriodAsync(
        [Description("Data inicial no formato yyyy-MM-dd.")] string startDate,
        [Description("Data final no formato yyyy-MM-dd.")] string endDate,
        [Description("Agrupamento permitido: day, month ou year.")] string groupBy,
        CancellationToken cancellationToken)
        => _analyticsService.GetRevenueByPeriodAsync(startDate, endDate, groupBy, cancellationToken);

    [McpServerTool(Name = "get_top_products", Title = "Top products")]
    [Description("Retorna os produtos com maior volume de vendas ou maior valor liquido vendido.")]
    [Authorize]
    public Task<TopProductsResultDto> GetTopProductsAsync(
        [Description("Data inicial no formato yyyy-MM-dd.")] string startDate,
        [Description("Data final no formato yyyy-MM-dd.")] string endDate,
        [Description("Quantidade maxima de itens retornados.")] int limit,
        [Description("Ordenacao permitida: unitsSold ou netSales.")] string sortBy,
        CancellationToken cancellationToken)
        => _analyticsService.GetTopProductsAsync(startDate, endDate, limit, sortBy, cancellationToken);

    [McpServerTool(Name = "get_top_customers", Title = "Top customers")]
    [Description("Retorna os clientes com maior faturamento ou maior numero de pedidos.")]
    [Authorize]
    public Task<TopCustomersResultDto> GetTopCustomersAsync(
        [Description("Data inicial no formato yyyy-MM-dd.")] string startDate,
        [Description("Data final no formato yyyy-MM-dd.")] string endDate,
        [Description("Quantidade maxima de itens retornados.")] int limit,
        [Description("Ordenacao permitida: grossSales ou orderCount.")] string sortBy,
        CancellationToken cancellationToken)
        => _analyticsService.GetTopCustomersAsync(startDate, endDate, limit, sortBy, cancellationToken);

    [McpServerTool(Name = "get_sales_by_channel", Title = "Sales by channel")]
    [Description("Retorna faturamento e quantidade de pedidos por canal de venda.")]
    [Authorize]
    public Task<SalesByChannelResultDto> GetSalesByChannelAsync(
        [Description("Data inicial no formato yyyy-MM-dd.")] string startDate,
        [Description("Data final no formato yyyy-MM-dd.")] string endDate,
        CancellationToken cancellationToken)
        => _analyticsService.GetSalesByChannelAsync(startDate, endDate, cancellationToken);

    [McpServerTool(Name = "get_order_status_summary", Title = "Order status summary")]
    [Description("Retorna um resumo da quantidade de pedidos por status em um intervalo.")]
    [Authorize]
    public Task<OrderStatusSummaryResultDto> GetOrderStatusSummaryAsync(
        [Description("Data inicial no formato yyyy-MM-dd.")] string startDate,
        [Description("Data final no formato yyyy-MM-dd.")] string endDate,
        CancellationToken cancellationToken)
        => _analyticsService.GetOrderStatusSummaryAsync(startDate, endDate, cancellationToken);

    [McpServerTool(Name = "get_recent_orders", Title = "Recent orders")]
    [Description("Retorna pedidos mais recentes, com filtros opcionais por status e codigo do cliente.")]
    [Authorize]
    public Task<RecentOrdersResultDto> GetRecentOrdersAsync(
        [Description("Quantidade maxima de pedidos retornados.")] int limit,
        [Description("Codigo de status opcional, por exemplo DELIVERED.")] string? statusCode,
        [Description("Codigo do cliente opcional, por exemplo CUS000123.")] string? customerCode,
        CancellationToken cancellationToken)
        => _analyticsService.GetRecentOrdersAsync(limit, statusCode, customerCode, cancellationToken);

    // Sales Rep Analysis Tools

    [McpServerTool(Name = "get_top_sales_reps", Title = "Top sales representatives")]
    [Description("Retorna os vendedores com melhor performance por receita, numero de pedidos, ticket medio ou comissao.")]
    [Authorize]
    public Task<TopSalesRepsResultDto> GetTopSalesRepsAsync(
        [Description("Data inicial no formato yyyy-MM-dd.")] string startDate,
        [Description("Data final no formato yyyy-MM-dd.")] string endDate,
        [Description("Quantidade maxima de vendedores retornados.")] int limit,
        [Description("Ordenacao permitida: revenue, orderCount, averageOrderValue ou commissionAmount.")] string sortBy,
        CancellationToken cancellationToken)
        => _analyticsService.GetTopSalesRepsAsync(startDate, endDate, limit, sortBy, cancellationToken);

    [McpServerTool(Name = "get_sales_rep_performance_trend", Title = "Sales rep performance trend")]
    [Description("Retorna a evolucao de performance de um vendedor especifico ao longo do tempo.")]
    [Authorize]
    public Task<SalesRepPerformanceTrendResultDto> GetSalesRepPerformanceTrendAsync(
        [Description("Codigo do vendedor, por exemplo REP001.")] string salesRepCode,
        [Description("Data inicial no formato yyyy-MM-dd.")] string startDate,
        [Description("Data final no formato yyyy-MM-dd.")] string endDate,
        [Description("Agrupamento permitido: day, month ou year.")] string groupBy,
        CancellationToken cancellationToken)
        => _analyticsService.GetSalesRepPerformanceTrendAsync(salesRepCode, startDate, endDate, groupBy, cancellationToken);

    [McpServerTool(Name = "get_sales_rep_commission_summary", Title = "Sales rep commission summary")]
    [Description("Retorna um resumo de comissoes por vendedor em um periodo.")]
    [Authorize]
    public Task<SalesRepCommissionResultDto> GetSalesRepCommissionSummaryAsync(
        [Description("Data inicial no formato yyyy-MM-dd.")] string startDate,
        [Description("Data final no formato yyyy-MM-dd.")] string endDate,
        CancellationToken cancellationToken)
        => _analyticsService.GetSalesRepCommissionSummaryAsync(startDate, endDate, cancellationToken);

    [McpServerTool(Name = "get_sales_rep_customer_analysis", Title = "Sales rep customer analysis")]
    [Description("Analise de perfil de clientes por vendedor: novos clientes, clientes recorrentes e taxa de retencao.")]
    [Authorize]
    public Task<SalesRepCustomerResultDto> GetSalesRepCustomerAnalysisAsync(
        [Description("Data inicial no formato yyyy-MM-dd.")] string startDate,
        [Description("Data final no formato yyyy-MM-dd.")] string endDate,
        CancellationToken cancellationToken)
        => _analyticsService.GetSalesRepCustomerAnalysisAsync(startDate, endDate, cancellationToken);

    [McpServerTool(Name = "get_sales_rep_conversion_analysis", Title = "Sales rep conversion analysis")]
    [Description("Analise de metricas de conversao por vendedor: taxa de conversao, ciclo de vendas e win rate.")]
    [Authorize]
    public Task<SalesRepConversionResultDto> GetSalesRepConversionAnalysisAsync(
        [Description("Data inicial no formato yyyy-MM-dd.")] string startDate,
        [Description("Data final no formato yyyy-MM-dd.")] string endDate,
        CancellationToken cancellationToken)
        => _analyticsService.GetSalesRepConversionAnalysisAsync(startDate, endDate, cancellationToken);

    [McpServerTool(Name = "get_sales_rep_comparative_analysis", Title = "Sales rep comparative analysis")]
    [Description("Analise comparativa entre vendedores com metricas normalizadas em relacao a media da equipe.")]
    [Authorize]
    public Task<SalesRepComparativeResultDto> GetSalesRepComparativeAnalysisAsync(
        [Description("Data inicial no formato yyyy-MM-dd.")] string startDate,
        [Description("Data final no formato yyyy-MM-dd.")] string endDate,
        CancellationToken cancellationToken)
        => _analyticsService.GetSalesRepComparativeAnalysisAsync(startDate, endDate, cancellationToken);

    [McpServerTool(Name = "get_sales_targets", Title = "Sales targets")]
    [Description("Retorna as metas de venda por vendedor e mes, dentro de um intervalo de datas.")]
    [Authorize]
    public Task<SalesTargetResultDto> GetSalesTargetsAsync(
        [Description("Data inicial no formato yyyy-MM-dd.")] string startDate,
        [Description("Data final no formato yyyy-MM-dd.")] string endDate,
        [Description("Codigo do vendedor (ex: REP001); opcional.")] string? salesRepCode,
        CancellationToken cancellationToken)
        => _analyticsService.GetSalesTargetsAsync(startDate, endDate, salesRepCode, cancellationToken);

    [McpServerTool(Name = "get_sales_target_attainment", Title = "Sales target attainment")]
    [Description("Compara a meta de venda com o faturamento real por vendedor e mes, com percentual de atingimento, dentro de um intervalo de datas.")]
    [Authorize]
    public Task<SalesTargetAttainmentResultDto> GetSalesTargetAttainmentAsync(
        [Description("Data inicial no formato yyyy-MM-dd.")] string startDate,
        [Description("Data final no formato yyyy-MM-dd.")] string endDate,
        [Description("Codigo do vendedor (ex: REP001); opcional.")] string? salesRepCode,
        CancellationToken cancellationToken)
        => _analyticsService.GetSalesTargetAttainmentAsync(startDate, endDate, salesRepCode, cancellationToken);
}

