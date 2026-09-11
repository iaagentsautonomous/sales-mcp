using Dapper;
using Sales.Mcp.Application.Abstractions;
using Sales.Mcp.Application.Dtos;
using Sales.Mcp.Application.Validation;

namespace Sales.Mcp.Application.Services;

public sealed class SalesAnalyticsService
{
    private const string RevenueStatuses = "('PAID','PARTIALLY_REFUNDED','REFUNDED')";
    private readonly ISqlConnectionFactory _connectionFactory;
    private readonly ToolArgumentValidator _validator;

    public SalesAnalyticsService(ISqlConnectionFactory connectionFactory, ToolArgumentValidator validator)
    {
        _connectionFactory = connectionFactory;
        _validator = validator;
    }

    public async Task<RevenueByPeriodResultDto> GetRevenueByPeriodAsync(string startDate, string endDate, string groupBy, CancellationToken cancellationToken)
    {
        var range = _validator.ValidateDateRange(startDate, endDate);
        var normalizedGroupBy = _validator.ValidateRevenueGroupBy(groupBy);
        var groupExpression = normalizedGroupBy switch
        {
            "day" => "CAST(o.OrderDate AS date)",
            "year" => "DATEFROMPARTS(YEAR(o.OrderDate), 1, 1)",
            _ => "DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1)"
        };

        var sql = $"""
            SELECT
                CONVERT(varchar(10), {groupExpression}, 23) AS PeriodStart,
                CAST(ROUND(SUM(CASE WHEN ps.StatusCode IN {RevenueStatuses} THEN o.TotalAmount ELSE 0 END), 2) AS decimal(18,2)) AS GrossRevenue,
                CAST(ROUND(SUM(CASE WHEN ps.StatusCode = 'REFUNDED' THEN ISNULL(rh.RefundAmount, 0) ELSE 0 END), 2) AS decimal(18,2)) AS RefundedRevenue,
                COUNT(*) AS OrderCount
            FROM sales.SalesOrder AS o
            INNER JOIN sales.Payment AS p
                ON p.OrderId = o.OrderId
            INNER JOIN sales.PaymentStatus AS ps
                ON ps.PaymentStatusId = p.PaymentStatusId
            LEFT JOIN
            (
                SELECT OrderId, SUM(RefundAmount) AS RefundAmount
                FROM sales.ReturnHeader AS rh
                INNER JOIN sales.ReturnStatus AS rs
                    ON rs.ReturnStatusId = rh.ReturnStatusId
                WHERE rs.StatusCode = 'REFUNDED'
                GROUP BY OrderId
            ) AS rh
                ON rh.OrderId = o.OrderId
            WHERE o.OrderDate >= @StartDate
              AND o.OrderDate < @EndDateExclusive
            GROUP BY {groupExpression}
            ORDER BY {groupExpression};
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = (await connection.QueryAsync<RevenuePointDto>(new CommandDefinition(
            sql,
            new
            {
                StartDate = range.StartAtMidnight,
                EndDateExclusive = range.EndExclusive
            },
            cancellationToken: cancellationToken))).AsList();

        return new RevenueByPeriodResultDto(startDate, endDate, normalizedGroupBy, rows);
    }

    public async Task<TopProductsResultDto> GetTopProductsAsync(string startDate, string endDate, int limit, string sortBy, CancellationToken cancellationToken)
    {
        var range = _validator.ValidateDateRange(startDate, endDate);
        var normalizedLimit = _validator.ValidateLimit(limit);
        var normalizedSortBy = _validator.ValidateTopProductSortBy(sortBy);
        var orderBy = normalizedSortBy == "netSales" ? "NetSales DESC, UnitsSold DESC, ProductName" : "UnitsSold DESC, NetSales DESC, ProductName";

        var sql = $"""
            SELECT TOP (@Limit)
                p.ProductName,
                SUM(oi.Quantity) AS UnitsSold,
                CAST(ROUND(SUM(oi.LineTotal), 2) AS decimal(18,2)) AS NetSales
            FROM sales.SalesOrderItem AS oi
            INNER JOIN sales.SalesOrder AS o
                ON o.OrderId = oi.OrderId
            INNER JOIN sales.Payment AS pay
                ON pay.OrderId = o.OrderId
            INNER JOIN sales.PaymentStatus AS ps
                ON ps.PaymentStatusId = pay.PaymentStatusId
            INNER JOIN sales.Product AS p
                ON p.ProductId = oi.ProductId
            WHERE o.OrderDate >= @StartDate
              AND o.OrderDate < @EndDateExclusive
              AND ps.StatusCode IN {RevenueStatuses}
            GROUP BY p.ProductName
            ORDER BY {orderBy};
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = (await connection.QueryAsync<TopProductDto>(new CommandDefinition(
            sql,
            new
            {
                Limit = normalizedLimit,
                StartDate = range.StartAtMidnight,
                EndDateExclusive = range.EndExclusive
            },
            cancellationToken: cancellationToken))).AsList();

        return new TopProductsResultDto(startDate, endDate, normalizedLimit, normalizedSortBy, rows);
    }

    public async Task<TopCustomersResultDto> GetTopCustomersAsync(string startDate, string endDate, int limit, string sortBy, CancellationToken cancellationToken)
    {
        var range = _validator.ValidateDateRange(startDate, endDate);
        var normalizedLimit = _validator.ValidateLimit(limit);
        var normalizedSortBy = _validator.ValidateTopCustomerSortBy(sortBy);
        var orderBy = normalizedSortBy == "orderCount" ? "OrderCount DESC, GrossSales DESC, CustomerName" : "GrossSales DESC, OrderCount DESC, CustomerName";

        var sql = $"""
            SELECT TOP (@Limit)
                c.CustomerCode,
                c.CustomerName,
                COUNT(*) AS OrderCount,
                CAST(ROUND(SUM(o.TotalAmount), 2) AS decimal(18,2)) AS GrossSales
            FROM sales.SalesOrder AS o
            INNER JOIN sales.Payment AS p
                ON p.OrderId = o.OrderId
            INNER JOIN sales.PaymentStatus AS ps
                ON ps.PaymentStatusId = p.PaymentStatusId
            INNER JOIN sales.Customer AS c
                ON c.CustomerId = o.CustomerId
            WHERE o.OrderDate >= @StartDate
              AND o.OrderDate < @EndDateExclusive
              AND ps.StatusCode IN {RevenueStatuses}
            GROUP BY c.CustomerCode, c.CustomerName
            ORDER BY {orderBy};
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = (await connection.QueryAsync<TopCustomerDto>(new CommandDefinition(
            sql,
            new
            {
                Limit = normalizedLimit,
                StartDate = range.StartAtMidnight,
                EndDateExclusive = range.EndExclusive
            },
            cancellationToken: cancellationToken))).AsList();

        return new TopCustomersResultDto(startDate, endDate, normalizedLimit, normalizedSortBy, rows);
    }

    public async Task<SalesByChannelResultDto> GetSalesByChannelAsync(string startDate, string endDate, CancellationToken cancellationToken)
    {
        var range = _validator.ValidateDateRange(startDate, endDate);

        const string sql = """
            SELECT
                ch.ChannelName,
                COUNT(*) AS OrdersByChannel,
                CAST(ROUND(SUM(o.TotalAmount), 2) AS decimal(18,2)) AS GrossSalesByChannel
            FROM sales.SalesOrder AS o
            INNER JOIN sales.Payment AS p
                ON p.OrderId = o.OrderId
            INNER JOIN sales.PaymentStatus AS ps
                ON ps.PaymentStatusId = p.PaymentStatusId
            INNER JOIN sales.SalesChannel AS ch
                ON ch.SalesChannelId = o.SalesChannelId
            WHERE o.OrderDate >= @StartDate
              AND o.OrderDate < @EndDateExclusive
              AND ps.StatusCode IN ('PAID','PARTIALLY_REFUNDED','REFUNDED')
            GROUP BY ch.ChannelName
            ORDER BY GrossSalesByChannel DESC, ch.ChannelName;
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = (await connection.QueryAsync<ChannelSalesDto>(new CommandDefinition(
            sql,
            new
            {
                StartDate = range.StartAtMidnight,
                EndDateExclusive = range.EndExclusive
            },
            cancellationToken: cancellationToken))).AsList();

        return new SalesByChannelResultDto(startDate, endDate, rows);
    }

    public async Task<OrderStatusSummaryResultDto> GetOrderStatusSummaryAsync(string startDate, string endDate, CancellationToken cancellationToken)
    {
        var range = _validator.ValidateDateRange(startDate, endDate);

        const string sql = """
            SELECT
                os.StatusCode,
                os.StatusName,
                COUNT(*) AS Orders
            FROM sales.SalesOrder AS o
            INNER JOIN sales.OrderStatus AS os
                ON os.OrderStatusId = o.OrderStatusId
            WHERE o.OrderDate >= @StartDate
              AND o.OrderDate < @EndDateExclusive
            GROUP BY os.StatusCode, os.StatusName
            ORDER BY Orders DESC, os.StatusCode;
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = (await connection.QueryAsync<OrderStatusSummaryDto>(new CommandDefinition(
            sql,
            new
            {
                StartDate = range.StartAtMidnight,
                EndDateExclusive = range.EndExclusive
            },
            cancellationToken: cancellationToken))).AsList();

        return new OrderStatusSummaryResultDto(startDate, endDate, rows);
    }

    public async Task<RecentOrdersResultDto> GetRecentOrdersAsync(int limit, string? statusCode, string? customerCode, CancellationToken cancellationToken)
    {
        var normalizedLimit = _validator.ValidateLimit(limit);
        var normalizedStatusCode = _validator.NormalizeOptionalCode(statusCode);
        var normalizedCustomerCode = _validator.NormalizeOptionalCode(customerCode);

        const string sql = """
            SELECT TOP (@Limit)
                o.OrderNumber,
                c.CustomerCode,
                c.CustomerName,
                os.StatusCode,
                ch.ChannelCode,
                CONVERT(varchar(19), o.OrderDate, 126) AS OrderDate,
                o.TotalAmount
            FROM sales.SalesOrder AS o
            INNER JOIN sales.Customer AS c
                ON c.CustomerId = o.CustomerId
            INNER JOIN sales.OrderStatus AS os
                ON os.OrderStatusId = o.OrderStatusId
            INNER JOIN sales.SalesChannel AS ch
                ON ch.SalesChannelId = o.SalesChannelId
            WHERE (@StatusCode IS NULL OR os.StatusCode = @StatusCode)
              AND (@CustomerCode IS NULL OR c.CustomerCode = @CustomerCode)
            ORDER BY o.OrderDate DESC, o.OrderId DESC;
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = (await connection.QueryAsync<RecentOrderDto>(new CommandDefinition(
            sql,
            new
            {
                Limit = normalizedLimit,
                StatusCode = normalizedStatusCode,
                CustomerCode = normalizedCustomerCode
            },
            cancellationToken: cancellationToken))).AsList();

        return new RecentOrdersResultDto(normalizedLimit, normalizedStatusCode, normalizedCustomerCode, rows);
    }

    public async Task<TopSalesRepsResultDto> GetTopSalesRepsAsync(string startDate, string endDate, int limit, string sortBy, CancellationToken cancellationToken)
    {
        var range = _validator.ValidateDateRange(startDate, endDate);
        var normalizedLimit = _validator.ValidateLimit(limit);
        var normalizedSortBy = _validator.ValidateTopSalesRepSortBy(sortBy);
        var orderBy = normalizedSortBy switch
        {
            "orderCount" => "OrderCount DESC, TotalRevenue DESC, FullName",
            "averageOrderValue" => "AverageOrderValue DESC, TotalRevenue DESC, FullName",
            "commissionAmount" => "CommissionAmount DESC, TotalRevenue DESC, FullName",
            _ => "TotalRevenue DESC, OrderCount DESC, FullName" // revenue is default
        };

        var sql = $"""
            SELECT TOP (@Limit)
                sr.SalesRepCode,
                sr.FullName,
                CAST(ROUND(SUM(o.TotalAmount), 2) AS decimal(18,2)) AS TotalRevenue,
                COUNT(*) AS OrderCount,
                CAST(ROUND(AVG(o.TotalAmount), 2) AS decimal(18,2)) AS AverageOrderValue,
                CAST(ROUND(SUM(o.TotalAmount * sr.CommissionRate / 100.0), 2) AS decimal(18,2)) AS CommissionAmount,
                CAST(ROUND(COUNT(*) * 100.0 / NULLIF(COUNT(DISTINCT o.CustomerId), 0), 2) AS decimal(5,2)) AS ConversionRate
            FROM sales.SalesOrder AS o
            INNER JOIN sales.Payment AS p
                ON p.OrderId = o.OrderId
            INNER JOIN sales.PaymentStatus AS ps
                ON ps.PaymentStatusId = p.PaymentStatusId
            INNER JOIN sales.SalesRep AS sr
                ON sr.SalesRepId = o.SalesRepId
            WHERE o.OrderDate >= @StartDate
              AND o.OrderDate < @EndDateExclusive
              AND ps.StatusCode IN {RevenueStatuses}
              AND sr.IsActive = 1
            GROUP BY sr.SalesRepCode, sr.FullName, sr.CommissionRate
            ORDER BY {orderBy};
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = (await connection.QueryAsync<SalesRepPerformanceDto>(new CommandDefinition(
            sql,
            new
            {
                Limit = normalizedLimit,
                StartDate = range.StartAtMidnight,
                EndDateExclusive = range.EndExclusive
            },
            cancellationToken: cancellationToken))).AsList();

        return new TopSalesRepsResultDto(startDate, endDate, normalizedLimit, normalizedSortBy, rows);
    }

    public async Task<SalesRepPerformanceTrendResultDto> GetSalesRepPerformanceTrendAsync(string salesRepCode, string startDate, string endDate, string groupBy, CancellationToken cancellationToken)
    {
        var range = _validator.ValidateDateRange(startDate, endDate);
        var normalizedGroupBy = _validator.ValidateRevenueGroupBy(groupBy);
        var normalizedSalesRepCode = _validator.NormalizeCode(salesRepCode);
        
        var groupExpression = normalizedGroupBy switch
        {
            "day" => "CAST(o.OrderDate AS date)",
            "year" => "DATEFROMPARTS(YEAR(o.OrderDate), 1, 1)",
            _ => "DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1)"
        };

        var sql = $"""
            SELECT
                CONVERT(varchar(10), {groupExpression}, 23) AS Period,
                CAST(ROUND(SUM(o.TotalAmount), 2) AS decimal(18,2)) AS Revenue,
                COUNT(*) AS Orders,
                CAST(ROUND(SUM(o.TotalAmount * sr.CommissionRate / 100.0), 2) AS decimal(18,2)) AS Commission,
                CAST(ROUND(AVG(o.TotalAmount), 2) AS decimal(18,2)) AS AverageOrderValue
            FROM sales.SalesOrder AS o
            INNER JOIN sales.Payment AS p
                ON p.OrderId = o.OrderId
            INNER JOIN sales.PaymentStatus AS ps
                ON ps.PaymentStatusId = p.PaymentStatusId
            INNER JOIN sales.SalesRep AS sr
                ON sr.SalesRepId = o.SalesRepId
            WHERE sr.SalesRepCode = @SalesRepCode
              AND o.OrderDate >= @StartDate
              AND o.OrderDate < @EndDateExclusive
              AND ps.StatusCode IN {RevenueStatuses}
            GROUP BY {groupExpression}
            ORDER BY {groupExpression};
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = (await connection.QueryAsync<SalesRepTrendPointDto>(new CommandDefinition(
            sql,
            new
            {
                SalesRepCode = normalizedSalesRepCode,
                StartDate = range.StartAtMidnight,
                EndDateExclusive = range.EndExclusive
            },
            cancellationToken: cancellationToken))).AsList();

        // Get sales rep name for the result
        var salesRepNameSql = "SELECT FullName FROM sales.SalesRep WHERE SalesRepCode = @SalesRepCode";
        var salesRepName = await connection.QueryFirstOrDefaultAsync<string>(
            new CommandDefinition(salesRepNameSql, new { SalesRepCode = normalizedSalesRepCode }, cancellationToken: cancellationToken));

        return new SalesRepPerformanceTrendResultDto(
            salesRepCode, 
            salesRepName ?? "Unknown", 
            startDate, 
            endDate, 
            normalizedGroupBy, 
            rows);
    }

    public async Task<SalesRepCommissionResultDto> GetSalesRepCommissionSummaryAsync(string startDate, string endDate, CancellationToken cancellationToken)
    {
        var range = _validator.ValidateDateRange(startDate, endDate);

        var sql = $"""
            SELECT
                sr.SalesRepCode,
                sr.FullName,
                CAST(ROUND(SUM(o.TotalAmount), 2) AS decimal(18,2)) AS TotalRevenue,
                CAST(ROUND(SUM(o.TotalAmount * sr.CommissionRate / 100.0), 2) AS decimal(18,2)) AS TotalCommission,
                sr.CommissionRate,
                COUNT(*) AS OrderCount
            FROM sales.SalesOrder AS o
            INNER JOIN sales.Payment AS p
                ON p.OrderId = o.OrderId
            INNER JOIN sales.PaymentStatus AS ps
                ON ps.PaymentStatusId = p.PaymentStatusId
            INNER JOIN sales.SalesRep AS sr
                ON sr.SalesRepId = o.SalesRepId
            WHERE o.OrderDate >= @StartDate
              AND o.OrderDate < @EndDateExclusive
              AND ps.StatusCode IN {RevenueStatuses}
              AND sr.IsActive = 1
            GROUP BY sr.SalesRepCode, sr.FullName, sr.CommissionRate
            ORDER BY TotalCommission DESC, TotalRevenue DESC;
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = (await connection.QueryAsync<SalesRepCommissionSummaryDto>(new CommandDefinition(
            sql,
            new
            {
                StartDate = range.StartAtMidnight,
                EndDateExclusive = range.EndExclusive
            },
            cancellationToken: cancellationToken))).AsList();

        return new SalesRepCommissionResultDto(startDate, endDate, rows);
    }

    public async Task<SalesRepCustomerResultDto> GetSalesRepCustomerAnalysisAsync(string startDate, string endDate, CancellationToken cancellationToken)
    {
        var range = _validator.ValidateDateRange(startDate, endDate);

        var sql = $"""
            WITH CustomerStats AS (
                SELECT
                    sr.SalesRepCode,
                    sr.FullName,
                    o.CustomerId,
                    COUNT(*) AS OrderCount,
                    SUM(o.TotalAmount) AS TotalSpent,
                    MIN(o.OrderDate) AS FirstOrderDate,
                    MAX(o.OrderDate) AS LastOrderDate
                FROM sales.SalesOrder AS o
                INNER JOIN sales.Payment AS p
                    ON p.OrderId = o.OrderId
                INNER JOIN sales.PaymentStatus AS ps
                    ON ps.PaymentStatusId = p.PaymentStatusId
                INNER JOIN sales.SalesRep AS sr
                    ON sr.SalesRepId = o.SalesRepId
                WHERE o.OrderDate >= @StartDate
                  AND o.OrderDate < @EndDateExclusive
                  AND ps.StatusCode IN {RevenueStatuses}
                  AND sr.IsActive = 1
                GROUP BY sr.SalesRepCode, sr.FullName, o.CustomerId
            ),
            RepSummary AS (
                SELECT
                    SalesRepCode,
                    FullName,
                    COUNT(DISTINCT CustomerId) AS TotalCustomers,
                    SUM(CASE WHEN OrderCount = 1 THEN 1 ELSE 0 END) AS NewCustomers,
                    SUM(CASE WHEN OrderCount > 1 THEN 1 ELSE 0 END) AS RepeatCustomers,
                    CAST(ROUND(SUM(TotalSpent), 2) AS decimal(18,2)) AS TotalRevenue,
                    CAST(ROUND(AVG(TotalSpent), 2) AS decimal(18,2)) AS AverageCustomerValue
                FROM CustomerStats
                GROUP BY SalesRepCode, FullName
            )
            SELECT
                SalesRepCode,
                FullName,
                TotalCustomers,
                NewCustomers,
                RepeatCustomers,
                CAST(ROUND(RepeatCustomers * 100.0 / NULLIF(TotalCustomers, 0), 2) AS decimal(5,2)) AS CustomerRetentionRate,
                AverageCustomerValue
            FROM RepSummary
            ORDER BY TotalCustomers DESC, TotalRevenue DESC;
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = (await connection.QueryAsync<SalesRepCustomerAnalysisDto>(new CommandDefinition(
            sql,
            new
            {
                StartDate = range.StartAtMidnight,
                EndDateExclusive = range.EndExclusive
            },
            cancellationToken: cancellationToken))).AsList();

        return new SalesRepCustomerResultDto(startDate, endDate, rows);
    }

    public async Task<SalesRepConversionResultDto> GetSalesRepConversionAnalysisAsync(string startDate, string endDate, CancellationToken cancellationToken)
    {
        var range = _validator.ValidateDateRange(startDate, endDate);

        var sql = """
            WITH RepOpportunities AS (
                SELECT
                    sr.SalesRepCode,
                    sr.FullName,
                    COUNT(*) AS TotalOpportunities,
                    COUNT(CASE WHEN ps.StatusCode IN ('PAID','PARTIALLY_REFUNDED','REFUNDED') THEN 1 END) AS ConvertedOrders,
                    AVG(CASE 
                        WHEN ps.StatusCode IN ('PAID','PARTIALLY_REFUNDED','REFUNDED') 
                             AND o.ApprovedAt IS NOT NULL 
                        THEN DATEDIFF(DAY, o.OrderDate, o.ApprovedAt) 
                    END) AS AverageSalesCycleDays
                FROM sales.SalesOrder AS o
                INNER JOIN sales.SalesRep AS sr
                    ON sr.SalesRepId = o.SalesRepId
                INNER JOIN sales.Payment AS p
                    ON p.OrderId = o.OrderId
                INNER JOIN sales.PaymentStatus AS ps
                    ON ps.PaymentStatusId = p.PaymentStatusId
                WHERE o.OrderDate >= @StartDate
                  AND o.OrderDate < @EndDateExclusive
                  AND sr.IsActive = 1
                GROUP BY sr.SalesRepCode, sr.FullName
            )
            SELECT
                SalesRepCode,
                FullName,
                TotalOpportunities,
                ConvertedOrders,
                CAST(ROUND(ConvertedOrders * 100.0 / NULLIF(TotalOpportunities, 0), 1) AS decimal(5,1)) AS ConversionRate,
                CAST(ROUND(ISNULL(AverageSalesCycleDays, 0), 1) AS decimal(5,1)) AS AverageSalesCycleDays,
                CAST(ROUND(ConvertedOrders * 100.0 / NULLIF(TotalOpportunities, 0), 1) AS decimal(5,1)) AS WinRate
            FROM RepOpportunities
            ORDER BY ConversionRate DESC, TotalOpportunities DESC;
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = (await connection.QueryAsync<SalesRepConversionMetricsDto>(new CommandDefinition(
            sql,
            new
            {
                StartDate = range.StartAtMidnight,
                EndDateExclusive = range.EndExclusive
            },
            cancellationToken: cancellationToken))).AsList();

        return new SalesRepConversionResultDto(startDate, endDate, rows);
    }

    public async Task<SalesRepComparativeResultDto> GetSalesRepComparativeAnalysisAsync(string startDate, string endDate, CancellationToken cancellationToken)

    {
        var range = _validator.ValidateDateRange(startDate, endDate);

        var sql = $"""
            WITH RepMetrics AS (
                SELECT
                    sr.SalesRepCode,
                    sr.FullName,
                    COUNT(*) AS OrderCount,
                    SUM(o.TotalAmount) AS TotalRevenue,
                    AVG(o.TotalAmount) AS AvgOrderValue,
                    COUNT(DISTINCT o.CustomerId) AS UniqueCustomers,
                    DATEDIFF(DAY, MIN(o.OrderDate), MAX(o.OrderDate)) + 1 AS ActiveDays
                FROM sales.SalesOrder AS o
                INNER JOIN sales.Payment AS p
                    ON p.OrderId = o.OrderId
                INNER JOIN sales.PaymentStatus AS ps
                    ON ps.PaymentStatusId = p.PaymentStatusId
                INNER JOIN sales.SalesRep AS sr
                    ON sr.SalesRepId = o.SalesRepId
                WHERE o.OrderDate >= @StartDate
                  AND o.OrderDate < @EndDateExclusive
                  AND ps.StatusCode IN ('PAID','PARTIALLY_REFUNDED','REFUNDED')
                  AND sr.IsActive = 1
                GROUP BY sr.SalesRepCode, sr.FullName
            ),
            TeamAverages AS (
                SELECT
                    AVG(OrderCount) AS AvgOrders,
                    AVG(TotalRevenue) AS AvgRevenue,
                    AVG(AvgOrderValue) AS AvgOrderValue,
                    AVG(CAST(UniqueCustomers AS decimal)) AS AvgCustomers,
                    MAX(TotalRevenue) AS TopRevenue,
                    MAX(OrderCount) AS TopOrders,
                    MAX(AvgOrderValue) AS TopOrderValue,
                    MAX(UniqueCustomers) AS TopCustomers
                FROM RepMetrics
            )
            SELECT
                rm.SalesRepCode,
                rm.FullName,
                JSON_QUERY(j.MetricsJson) AS MetricsJson
            FROM RepMetrics rm
            CROSS JOIN TeamAverages ta
            CROSS APPLY (
                SELECT (
                    SELECT *
                    FROM (
                        SELECT
                            'Revenue' AS MetricName,
                            rm.TotalRevenue AS SalesRepValue,
                            ta.AvgRevenue AS TeamAverage,
                            ta.TopRevenue AS TeamTopPerformer,
                            rm.TotalRevenue - ta.AvgRevenue AS DifferenceFromAverage

                        UNION ALL

                        SELECT
                            'OrderCount',
                            CAST(rm.OrderCount AS decimal),
                            ta.AvgOrders,
                            CAST(ta.TopOrders AS decimal),
                            CAST(rm.OrderCount AS decimal) - ta.AvgOrders

                        UNION ALL

                        SELECT
                            'AverageOrderValue',
                            rm.AvgOrderValue,
                            ta.AvgOrderValue,
                            ta.TopOrderValue,
                            rm.AvgOrderValue - ta.AvgOrderValue

                        UNION ALL

                        SELECT
                            'UniqueCustomers',
                            CAST(rm.UniqueCustomers AS decimal),
                            ta.AvgCustomers,
                            CAST(ta.TopCustomers AS decimal),
                            CAST(rm.UniqueCustomers AS decimal) - ta.AvgCustomers
                    ) AS Metrics
                    FOR JSON PATH
                ) AS MetricsJson
            ) j
            ORDER BY rm.TotalRevenue DESC;
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = await connection.QueryAsync<(string SalesRepCode, string FullName, string MetricsJson)>(
            new CommandDefinition(sql, new { StartDate = range.StartAtMidnight, EndDateExclusive = range.EndExclusive }, cancellationToken: cancellationToken));

        var result = new List<SalesRepComparativeAnalysisDto>();
        
        foreach (var row in rows)
        {
            var metrics = System.Text.Json.JsonSerializer.Deserialize<List<ComparativeAnalysisPointDto>>(row.MetricsJson ?? "[]");
            result.Add(new SalesRepComparativeAnalysisDto(row.SalesRepCode, row.FullName, metrics ?? new List<ComparativeAnalysisPointDto>()));
        }

        return new SalesRepComparativeResultDto(startDate, endDate, result);
    }
}
