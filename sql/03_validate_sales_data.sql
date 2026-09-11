SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE A2A;

IF SCHEMA_ID(N'sales') IS NULL
BEGIN
    THROW 50010, 'O schema sales nao existe no banco A2A.', 1;
END;

DECLARE @StartDate DATE = '20250101';
DECLARE @EndDate DATE = CAST(SYSDATETIME() AS DATE);
DECLARE @PaidPaymentStatusId INT = (SELECT PaymentStatusId FROM sales.PaymentStatus WHERE StatusCode = 'PAID');
DECLARE @PartialRefundPaymentStatusId INT = (SELECT PaymentStatusId FROM sales.PaymentStatus WHERE StatusCode = 'PARTIALLY_REFUNDED');
DECLARE @RefundedPaymentStatusId INT = (SELECT PaymentStatusId FROM sales.PaymentStatus WHERE StatusCode = 'REFUNDED');
DECLARE @RefundedReturnStatusId INT = (SELECT ReturnStatusId FROM sales.ReturnStatus WHERE StatusCode = 'REFUNDED');

IF EXISTS
(
    SELECT 1
    FROM sys.foreign_keys AS fk
    INNER JOIN sys.schemas AS s
        ON s.schema_id = fk.schema_id
    WHERE s.name = 'sales'
      AND (fk.is_disabled = 1 OR fk.is_not_trusted = 1)
)
BEGIN
    THROW 50011, 'Existem foreign keys desabilitadas ou nao confiaveis no schema sales.', 1;
END;

IF (SELECT COUNT(*) FROM sales.Category) <> 12 THROW 50012, 'Quantidade inesperada em sales.Category.', 1;
IF (SELECT COUNT(*) FROM sales.Subcategory) <> 36 THROW 50013, 'Quantidade inesperada em sales.Subcategory.', 1;
IF (SELECT COUNT(*) FROM sales.Supplier) <> 30 THROW 50014, 'Quantidade inesperada em sales.Supplier.', 1;
IF (SELECT COUNT(*) FROM sales.Brand) <> 20 THROW 50015, 'Quantidade inesperada em sales.Brand.', 1;
IF (SELECT COUNT(*) FROM sales.Product) <> 400 THROW 50016, 'Quantidade inesperada em sales.Product.', 1;
IF (SELECT COUNT(*) FROM sales.Customer) <> 2000 THROW 50017, 'Quantidade inesperada em sales.Customer.', 1;
IF (SELECT COUNT(*) FROM sales.CustomerAddress) <> 3000 THROW 50018, 'Quantidade inesperada em sales.CustomerAddress.', 1;
IF (SELECT COUNT(*) FROM sales.SalesRep) <> 12 THROW 50019, 'Quantidade inesperada em sales.SalesRep.', 1;
IF (SELECT COUNT(*) FROM sales.SalesChannel) <> 4 THROW 50020, 'Quantidade inesperada em sales.SalesChannel.', 1;
IF (SELECT COUNT(*) FROM sales.PaymentMethod) <> 6 THROW 50021, 'Quantidade inesperada em sales.PaymentMethod.', 1;
IF (SELECT COUNT(*) FROM sales.SalesOrder) <> 25000 THROW 50022, 'Quantidade inesperada em sales.SalesOrder.', 1;

IF (SELECT COUNT(*) FROM sales.Payment) <> 25000 THROW 50023, 'Quantidade inesperada em sales.Payment.', 1;
IF (SELECT COUNT(*) FROM sales.Shipment) <> 22000 THROW 50024, 'Quantidade inesperada em sales.Shipment.', 1;

IF (SELECT COUNT(*) FROM sales.ReturnHeader) NOT BETWEEN 1000 AND 1500
BEGIN
    THROW 50025, 'Quantidade inesperada em sales.ReturnHeader.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM sales.SalesOrder AS o
    LEFT JOIN sales.SalesOrderItem AS oi
        ON oi.OrderId = o.OrderId
    WHERE oi.OrderItemId IS NULL
)
BEGIN
    THROW 50026, 'Existe pedido sem item.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM sales.Payment AS p
    LEFT JOIN sales.SalesOrder AS o
        ON o.OrderId = p.OrderId
    WHERE o.OrderId IS NULL
)
BEGIN
    THROW 50027, 'Existe pagamento sem pedido.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM sales.Shipment AS s
    LEFT JOIN sales.SalesOrder AS o
        ON o.OrderId = s.OrderId
    WHERE o.OrderId IS NULL
)
BEGIN
    THROW 50028, 'Existe envio sem pedido.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM sales.ReturnItem AS ri
    LEFT JOIN sales.SalesOrderItem AS oi
        ON oi.OrderItemId = ri.OrderItemId
    WHERE oi.OrderItemId IS NULL
)
BEGIN
    THROW 50029, 'Existe item de devolucao sem item original.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM sales.SalesOrder
    WHERE CAST(OrderDate AS DATE) < @StartDate
       OR CAST(OrderDate AS DATE) > @EndDate
)
BEGIN
    THROW 50030, 'Existem pedidos fora do intervalo de datas esperado.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM sales.Payment
    WHERE CAST(PaymentDate AS DATE) < @StartDate
       OR CAST(PaymentDate AS DATE) > DATEADD(DAY, 3, @EndDate)
)
BEGIN
    THROW 50031, 'Existem pagamentos fora do intervalo esperado.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM sales.Shipment
    WHERE CAST(ShippedAt AS DATE) < @StartDate
       OR CAST(ShippedAt AS DATE) > @EndDate
       OR (DeliveredAt IS NOT NULL AND CAST(DeliveredAt AS DATE) > @EndDate)
)
BEGIN
    THROW 50032, 'Existem envios fora do intervalo esperado.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM sales.ReturnHeader
    WHERE CAST(RequestedAt AS DATE) < @StartDate
       OR CAST(RequestedAt AS DATE) > @EndDate
       OR (CompletedAt IS NOT NULL AND CAST(CompletedAt AS DATE) > @EndDate)
)
BEGIN
    THROW 50033, 'Existem devolucoes fora do intervalo esperado.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM sales.SalesOrder AS o
    CROSS APPLY
    (
        SELECT
            CAST(ROUND(SUM(oi.Quantity * oi.UnitPrice), 2) AS DECIMAL(18,2)) AS GrossSubtotal,
            CAST(ROUND(SUM(oi.DiscountAmount), 2) AS DECIMAL(18,2)) AS TotalDiscount
        FROM sales.SalesOrderItem AS oi
        WHERE oi.OrderId = o.OrderId
    ) AS calc
    WHERE ABS(calc.GrossSubtotal - o.Subtotal) > 0.05
       OR ABS(calc.TotalDiscount - o.DiscountAmount) > 0.05
       OR ABS((calc.GrossSubtotal - calc.TotalDiscount + o.ShippingAmount + o.TaxAmount) - o.TotalAmount) > 0.05
)
BEGIN
    THROW 50034, 'Existem pedidos com total incoerente em relacao aos itens.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM
    (
        SELECT ProductId, SUM(QuantityChange) AS StockBalance
        FROM sales.InventoryMovement
        GROUP BY ProductId
    ) AS stock
    INNER JOIN sales.Product AS p
        ON p.ProductId = stock.ProductId
    WHERE p.IsActive = 1
      AND stock.StockBalance < 0
)
BEGIN
    THROW 50035, 'Existem produtos ativos com estoque final negativo.', 1;
END;

SELECT
    summary.TableName,
    summary.TotalRows
FROM
(
    SELECT CAST('sales.Category' AS VARCHAR(50)) AS TableName, COUNT(*) AS TotalRows FROM sales.Category
    UNION ALL SELECT 'sales.Subcategory', COUNT(*) FROM sales.Subcategory
    UNION ALL SELECT 'sales.Supplier', COUNT(*) FROM sales.Supplier
    UNION ALL SELECT 'sales.Brand', COUNT(*) FROM sales.Brand
    UNION ALL SELECT 'sales.Product', COUNT(*) FROM sales.Product
    UNION ALL SELECT 'sales.Customer', COUNT(*) FROM sales.Customer
    UNION ALL SELECT 'sales.CustomerAddress', COUNT(*) FROM sales.CustomerAddress
    UNION ALL SELECT 'sales.SalesRep', COUNT(*) FROM sales.SalesRep
    UNION ALL SELECT 'sales.SalesOrder', COUNT(*) FROM sales.SalesOrder
    UNION ALL SELECT 'sales.SalesOrderItem', COUNT(*) FROM sales.SalesOrderItem
    UNION ALL SELECT 'sales.Payment', COUNT(*) FROM sales.Payment
    UNION ALL SELECT 'sales.Shipment', COUNT(*) FROM sales.Shipment
    UNION ALL SELECT 'sales.ReturnHeader', COUNT(*) FROM sales.ReturnHeader
    UNION ALL SELECT 'sales.ReturnItem', COUNT(*) FROM sales.ReturnItem
    UNION ALL SELECT 'sales.InventoryMovement', COUNT(*) FROM sales.InventoryMovement
) AS summary
ORDER BY summary.TableName;

SELECT
    DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1) AS RevenueMonth,
    CAST(ROUND(SUM(CASE WHEN p.PaymentStatusId IN (@PaidPaymentStatusId, @PartialRefundPaymentStatusId, @RefundedPaymentStatusId) THEN o.TotalAmount ELSE 0 END), 2) AS DECIMAL(18,2)) AS GrossRevenue,
    CAST(ROUND(SUM(CASE WHEN p.PaymentStatusId = @RefundedPaymentStatusId THEN ISNULL(rh.RefundAmount, 0) ELSE 0 END), 2) AS DECIMAL(18,2)) AS RefundedRevenue,
    COUNT(*) AS OrderCount
FROM sales.SalesOrder AS o
INNER JOIN sales.Payment AS p
    ON p.OrderId = o.OrderId
LEFT JOIN
(
    SELECT OrderId, SUM(RefundAmount) AS RefundAmount
    FROM sales.ReturnHeader
    WHERE ReturnStatusId = @RefundedReturnStatusId
    GROUP BY OrderId
) AS rh
    ON rh.OrderId = o.OrderId
GROUP BY DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1)
ORDER BY RevenueMonth;

SELECT TOP (10)
    p.ProductName,
    SUM(oi.Quantity) AS UnitsSold,
    CAST(ROUND(SUM(oi.LineTotal), 2) AS DECIMAL(18,2)) AS NetSales
FROM sales.SalesOrderItem AS oi
INNER JOIN sales.SalesOrder AS o
    ON o.OrderId = oi.OrderId
INNER JOIN sales.Payment AS pay
    ON pay.OrderId = o.OrderId
INNER JOIN sales.Product AS p
    ON p.ProductId = oi.ProductId
WHERE pay.PaymentStatusId IN
( @PaidPaymentStatusId, @PartialRefundPaymentStatusId, @RefundedPaymentStatusId )
GROUP BY p.ProductName
ORDER BY UnitsSold DESC, NetSales DESC;

SELECT
    ch.ChannelName,
    COUNT(*) AS OrdersByChannel,
    CAST(ROUND(SUM(o.TotalAmount), 2) AS DECIMAL(18,2)) AS GrossSalesByChannel
FROM sales.SalesOrder AS o
INNER JOIN sales.SalesChannel AS ch
    ON ch.SalesChannelId = o.SalesChannelId
GROUP BY ch.ChannelName
ORDER BY GrossSalesByChannel DESC;
