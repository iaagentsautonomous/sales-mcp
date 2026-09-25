namespace Sales.Mcp.Application.Dtos;

public sealed record RevenuePointDto(string PeriodStart, decimal GrossRevenue, decimal RefundedRevenue, int OrderCount);

public sealed record RevenueByPeriodResultDto(
    string StartDate,
    string EndDate,
    string GroupBy,
    IReadOnlyList<RevenuePointDto> Points);

public sealed record TopProductDto(string ProductName, int UnitsSold, decimal NetSales);

public sealed record TopProductsResultDto(
    string StartDate,
    string EndDate,
    int Limit,
    string SortBy,
    IReadOnlyList<TopProductDto> Items);

public sealed record TopCustomerDto(string CustomerCode, string CustomerName, int OrderCount, decimal GrossSales);

public sealed record TopCustomersResultDto(
    string StartDate,
    string EndDate,
    int Limit,
    string SortBy,
    IReadOnlyList<TopCustomerDto> Items);

public sealed record ChannelSalesDto(string ChannelName, int OrdersByChannel, decimal GrossSalesByChannel);

public sealed record SalesByChannelResultDto(
    string StartDate,
    string EndDate,
    IReadOnlyList<ChannelSalesDto> Items);

public sealed record OrderStatusSummaryDto(string StatusCode, string StatusName, int Orders);

public sealed record OrderStatusSummaryResultDto(
    string StartDate,
    string EndDate,
    IReadOnlyList<OrderStatusSummaryDto> Items);

public sealed record RecentOrderDto(
    string OrderNumber,
    string CustomerCode,
    string CustomerName,
    string StatusCode,
    string ChannelCode,
    string OrderDate,
    decimal TotalAmount);

public sealed record RecentOrdersResultDto(
    int Limit,
    string? StatusCode,
    string? CustomerCode,
    IReadOnlyList<RecentOrderDto> Items);

// Sales Rep Analysis DTOs
public sealed record SalesRepPerformanceDto(
    string SalesRepCode,
    string FullName,
    decimal TotalRevenue,
    int OrderCount,
    decimal AverageOrderValue,
    decimal CommissionAmount,
    decimal ConversionRate);

public sealed record TopSalesRepsResultDto(
    string StartDate,
    string EndDate,
    int Limit,
    string SortBy,
    IReadOnlyList<SalesRepPerformanceDto> Items);

public sealed record SalesRepTrendPointDto(
    string Period,
    decimal Revenue,
    int Orders,
    decimal Commission,
    decimal AverageOrderValue);

public sealed record SalesRepPerformanceTrendResultDto(
    string SalesRepCode,
    string FullName,
    string StartDate,
    string EndDate,
    string GroupBy,
    IReadOnlyList<SalesRepTrendPointDto> Points);

public sealed record SalesRepCommissionSummaryDto(
    string SalesRepCode,
    string FullName,
    decimal TotalRevenue,
    decimal TotalCommission,
    decimal CommissionRate,
    int OrderCount);

public sealed record SalesRepCommissionResultDto(
    string StartDate,
    string EndDate,
    IReadOnlyList<SalesRepCommissionSummaryDto> Items);

public sealed record SalesRepConversionMetricsDto(
    string SalesRepCode,
    string FullName,
    int TotalOpportunities,
    int ConvertedOrders,
    decimal ConversionRate,
    decimal AverageSalesCycleDays,
    decimal WinRate);

public sealed record SalesRepConversionResultDto(
    string StartDate,
    string EndDate,
    IReadOnlyList<SalesRepConversionMetricsDto> Items);

public sealed record SalesRepCustomerAnalysisDto(
    string SalesRepCode,
    string FullName,
    int TotalCustomers,
    int NewCustomers,
    int RepeatCustomers,
    decimal CustomerRetentionRate,
    decimal AverageCustomerValue);

public sealed record SalesRepCustomerResultDto(
    string StartDate,
    string EndDate,
    IReadOnlyList<SalesRepCustomerAnalysisDto> Items);

public sealed record SalesRepProductivityDto(
    string SalesRepCode,
    string FullName,
    int TotalActivities,
    int SalesCalls,
    int Meetings,
    decimal SalesPerHour,
    decimal ActivityToSaleRatio,
    decimal TimeToCloseDays);

public sealed record SalesRepProductivityResultDto(
    string StartDate,
    string EndDate,
    IReadOnlyList<SalesRepProductivityDto> Items);

public sealed record ComparativeAnalysisPointDto(
    string MetricName,
    decimal SalesRepValue,
    decimal TeamAverage,
    decimal TeamTopPerformer,
    decimal DifferenceFromAverage);

public sealed record SalesRepComparativeAnalysisDto(
    string SalesRepCode,
    string FullName,
    IReadOnlyList<ComparativeAnalysisPointDto> Metrics);

public sealed record SalesRepComparativeResultDto(
    string StartDate,
    string EndDate,
    IReadOnlyList<SalesRepComparativeAnalysisDto> Items);

// Sales Target DTOs
public sealed record SalesTargetDto(
    string SalesRepCode,
    string FullName,
    int TargetYear,
    int TargetMonth,
    decimal TargetAmount,
    string? Notes,
    bool IsActive);

public sealed record SalesTargetResultDto(
    string StartDate,
    string EndDate,
    string? SalesRepCode,
    IReadOnlyList<SalesTargetDto> Items);

public sealed record SalesTargetAttainmentDto(
    string SalesRepCode,
    string FullName,
    int TargetYear,
    int TargetMonth,
    decimal TargetAmount,
    decimal ActualRevenue,
    decimal AttainmentPercent);

public sealed record SalesTargetAttainmentResultDto(
    string StartDate,
    string EndDate,
    string? SalesRepCode,
    IReadOnlyList<SalesTargetAttainmentDto> Items);
