SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE A2A;

IF OBJECT_ID(N'sales.SalesOrder', N'U') IS NULL
BEGIN
    THROW 50001, 'O schema sales nao existe no banco A2A. Execute primeiro o script 01_create_sales_schema.sql.', 1;
END;

DECLARE @StartDate DATE = '20250101';
DECLARE @EndDate DATE = CAST(SYSDATETIME() AS DATE);
DECLARE @TotalDays INT;

IF @EndDate < @StartDate
BEGIN
    SET @EndDate = @StartDate;
END;

SET @TotalDays = DATEDIFF(DAY, @StartDate, @EndDate) + 1;

BEGIN TRANSACTION;

DELETE FROM sales.InventoryMovement;
DELETE FROM sales.ReturnItem;
DELETE FROM sales.ReturnHeader;
DELETE FROM sales.Shipment;
DELETE FROM sales.Payment;
DELETE FROM sales.SalesOrderItem;
DELETE FROM sales.SalesOrder;
DELETE FROM sales.CustomerAddress;
DELETE FROM sales.Product;
DELETE FROM sales.Subcategory;
DELETE FROM sales.Category;
DELETE FROM sales.Supplier;
DELETE FROM sales.Brand;
DELETE FROM sales.Customer;
DELETE FROM sales.SalesChannel;
DELETE FROM sales.SalesRep;
DELETE FROM sales.OrderStatus;
DELETE FROM sales.PaymentMethod;
DELETE FROM sales.PaymentStatus;
DELETE FROM sales.ShipmentCarrier;
DELETE FROM sales.ShipmentStatus;
DELETE FROM sales.ReturnReason;
DELETE FROM sales.ReturnStatus;
DELETE FROM sales.InventoryMovementType;

DBCC CHECKIDENT ('sales.Category', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.Subcategory', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.Supplier', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.Brand', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.Product', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.Customer', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.CustomerAddress', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.SalesChannel', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.SalesRep', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.OrderStatus', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.PaymentMethod', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.PaymentStatus', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.ShipmentCarrier', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.ShipmentStatus', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.ReturnReason', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.ReturnStatus', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.InventoryMovementType', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.SalesOrder', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.SalesOrderItem', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.Payment', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.Shipment', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.ReturnHeader', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.ReturnItem', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('sales.InventoryMovement', RESEED, 0) WITH NO_INFOMSGS;

SELECT TOP (100000)
       ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
INTO #Numbers
FROM sys.all_objects AS a
CROSS JOIN sys.all_objects AS b;

CREATE UNIQUE CLUSTERED INDEX IX_Numbers_N
    ON #Numbers(N);

INSERT INTO sales.OrderStatus (StatusCode, StatusName, SortOrder, IsFinal)
VALUES
    ('PENDING', N'Pendente', 10, 0),
    ('PAID', N'Pago', 20, 0),
    ('PICKING', N'Em separacao', 30, 0),
    ('SHIPPED', N'Enviado', 40, 0),
    ('DELIVERED', N'Entregue', 50, 1),
    ('PARTIALLY_RETURNED', N'Parcialmente devolvido', 60, 1),
    ('RETURNED', N'Devolvido', 70, 1),
    ('CANCELLED', N'Cancelado', 80, 1);

INSERT INTO sales.PaymentMethod (MethodCode, MethodName, Description)
VALUES
    ('CREDIT_CARD', N'Cartao de credito', N'Pagamento parcelado ou a vista no cartao de credito'),
    ('DEBIT_CARD', N'Cartao de debito', N'Pagamento a vista no cartao de debito'),
    ('PIX', N'PIX', N'Transferencia instantanea'),
    ('BANK_SLIP', N'Boleto bancario', N'Pagamento por boleto'),
    ('BANK_TRANSFER', N'Transferencia bancaria', N'TED ou DOC'),
    ('CASH', N'Dinheiro', N'Pagamento em especie');

SELECT
    PaymentMethodId,
    ROW_NUMBER() OVER (ORDER BY PaymentMethodId) AS RowNum
INTO #PaymentMethodMap
FROM sales.PaymentMethod;

CREATE UNIQUE CLUSTERED INDEX IX_PaymentMethodMap_RowNum
    ON #PaymentMethodMap(RowNum);

INSERT INTO sales.PaymentStatus (StatusCode, StatusName, IsSuccessful)
VALUES
    ('PENDING', N'Pendente', 0),
    ('AUTHORIZED', N'Autorizado', 0),
    ('PAID', N'Pago', 1),
    ('FAILED', N'Falhou', 0),
    ('PARTIALLY_REFUNDED', N'Parcialmente reembolsado', 1),
    ('REFUNDED', N'Reembolsado', 1);

INSERT INTO sales.SalesChannel (ChannelCode, ChannelName, Description)
VALUES
    ('STORE', N'Loja fisica', N'Vendas presenciais na loja'),
    ('ECOM', N'E-commerce', N'Vendas pelo site proprio'),
    ('MARKET', N'Marketplace', N'Vendas por parceiros digitais'),
    ('PHONE', N'Televendas', N'Pedidos realizados por telefone');

SELECT
    SalesChannelId,
    ROW_NUMBER() OVER (ORDER BY SalesChannelId) AS RowNum
INTO #SalesChannelMap
FROM sales.SalesChannel;

CREATE UNIQUE CLUSTERED INDEX IX_SalesChannelMap_RowNum
    ON #SalesChannelMap(RowNum);

INSERT INTO sales.ShipmentCarrier (CarrierCode, CarrierName, ServiceLevel, IsActive)
VALUES
    ('FASTEXP', N'Fast Express', N'Rodoviario expresso', 1),
    ('RAPIDLOG', N'Rapid Log', N'Economico', 1),
    ('ULTRACAR', N'Ultra Cargo', N'Standard', 1),
    ('BRMAIL', N'BR Mail', N'PAC e Sedex', 1),
    ('BLUEWAY', N'Blue Way', N'Ultima milha urbana', 1),
    ('NEXTRIP', N'Next Trip', N'Logistica regional', 1);

SELECT
    ShipmentCarrierId,
    ROW_NUMBER() OVER (ORDER BY ShipmentCarrierId) AS RowNum
INTO #ShipmentCarrierMap
FROM sales.ShipmentCarrier;

CREATE UNIQUE CLUSTERED INDEX IX_ShipmentCarrierMap_RowNum
    ON #ShipmentCarrierMap(RowNum);

INSERT INTO sales.ShipmentStatus (StatusCode, StatusName, SortOrder, IsFinal)
VALUES
    ('READY', N'Pronto para envio', 10, 0),
    ('SHIPPED', N'Postado', 20, 0),
    ('IN_TRANSIT', N'Em transito', 30, 0),
    ('DELIVERED', N'Entregue', 40, 1),
    ('RETURNED_TO_SENDER', N'Devolvido ao remetente', 50, 1),
    ('LOST', N'Extraviado', 60, 1);

INSERT INTO sales.ReturnReason (ReasonCode, ReasonName, IsCustomerFault)
VALUES
    ('DAMAGED', N'Produto avariado', 0),
    ('WRONG_ITEM', N'Produto incorreto', 0),
    ('LATE_DELIVERY', N'Atraso na entrega', 0),
    ('NO_LONGER_NEEDED', N'Arrependimento da compra', 1),
    ('SIZE_ISSUE', N'Tamanho ou medida inadequada', 1),
    ('DEFECTIVE', N'Defeito de fabrica', 0);

SELECT
    ReturnReasonId,
    ROW_NUMBER() OVER (ORDER BY ReturnReasonId) AS RowNum
INTO #ReturnReasonMap
FROM sales.ReturnReason;

CREATE UNIQUE CLUSTERED INDEX IX_ReturnReasonMap_RowNum
    ON #ReturnReasonMap(RowNum);

INSERT INTO sales.ReturnStatus (StatusCode, StatusName, IsFinal)
VALUES
    ('REQUESTED', N'Solicitado', 0),
    ('APPROVED', N'Aprovado', 0),
    ('RECEIVED', N'Recebido', 0),
    ('REFUNDED', N'Reembolsado', 1),
    ('REJECTED', N'Rejeitado', 1);

INSERT INTO sales.InventoryMovementType (MovementCode, MovementName, Direction)
VALUES
    ('INITIAL_STOCK', N'Estoque inicial', 'I'),
    ('PURCHASE_RECEIPT', N'Recebimento de compra', 'I'),
    ('SALE_OUT', N'Baixa por venda', 'O'),
    ('RETURN_IN', N'Retorno por devolucao', 'I');

INSERT INTO sales.Category (CategoryCode, CategoryName, Description)
VALUES
    ('ELETRON', N'Eletronicos', N'Produtos eletronicos e conectados'),
    ('INFORMAT', N'Informatica', N'Equipamentos e acessorios de informatica'),
    ('CASA', N'Casa e cozinha', N'Itens para o lar e cozinha'),
    ('ESPORTE', N'Esporte e lazer', N'Produtos esportivos e de lazer'),
    ('MODA', N'Moda', N'Vestuario, calcados e acessorios'),
    ('BELEZA', N'Beleza', N'Cosmeticos e cuidados pessoais'),
    ('SAUDE', N'Saude', N'Bem-estar e saude cotidiana'),
    ('FERRAM', N'Ferramentas', N'Ferramentas manuais e eletricas'),
    ('BRINQ', N'Brinquedos', N'Brinquedos e jogos'),
    ('AUTO', N'Automotivo', N'Acessorios automotivos'),
    ('PET', N'Pet shop', N'Produtos para animais'),
    ('PAPEL', N'Papelaria', N'Material escolar e de escritorio');

INSERT INTO sales.Subcategory (CategoryId, SubcategoryCode, SubcategoryName, Description)
SELECT c.CategoryId, v.SubcategoryCode, v.SubcategoryName, v.Description
FROM sales.Category AS c
INNER JOIN
(
    VALUES
        ('ELETRON', 'ELETRON-TV', N'TVs e audio', N'Televisores, soundbars e caixas'),
        ('ELETRON', 'ELETRON-SMART', N'Smart devices', N'Dispositivos conectados e IoT'),
        ('ELETRON', 'ELETRON-ENER', N'Energia e cabos', N'Cabos, filtros e carregadores'),
        ('INFORMAT', 'INFORMAT-NOTE', N'Notebooks', N'Computadores portateis'),
        ('INFORMAT', 'INFORMAT-PERIF', N'Perifericos', N'Teclados, mouses e headsets'),
        ('INFORMAT', 'INFORMAT-ARMAZ', N'Armazenamento', N'SSDs, HDDs e pen drives'),
        ('CASA', 'CASA-UTIL', N'Utilidades domesticas', N'Itens para organizacao da casa'),
        ('CASA', 'CASA-COOK', N'Panelas e cozinha', N'Utensilios e panelas'),
        ('CASA', 'CASA-DECOR', N'Decoracao', N'Objetos decorativos'),
        ('ESPORTE', 'ESPORTE-FIT', N'Fitness', N'Equipamentos para atividade fisica'),
        ('ESPORTE', 'ESPORTE-CAMP', N'Camping', N'Itens para aventura e camping'),
        ('ESPORTE', 'ESPORTE-BALL', N'Esportes de quadra', N'Bolas e acessorios esportivos'),
        ('MODA', 'MODA-ROUPA', N'Roupas', N'Camisetas, calcas e jaquetas'),
        ('MODA', 'MODA-CALC', N'Calcados', N'Tenis, sapatos e chinelos'),
        ('MODA', 'MODA-ACESS', N'Acessorios', N'Bolsas, cintos e oculos'),
        ('BELEZA', 'BELEZA-MAKE', N'Maquiagem', N'Itens de maquiagem'),
        ('BELEZA', 'BELEZA-HAIR', N'Cabelos', N'Cuidado e finalizacao'),
        ('BELEZA', 'BELEZA-SKIN', N'Skincare', N'Cuidado com a pele'),
        ('SAUDE', 'SAUDE-VIT', N'Vitaminas', N'Suplementos e vitaminas'),
        ('SAUDE', 'SAUDE-CUID', N'Cuidados diarios', N'Itens de higiene e saude'),
        ('SAUDE', 'SAUDE-ACESS', N'Acessorios de saude', N'Medidores e suportes'),
        ('FERRAM', 'FERRAM-MAN', N'Manuais', N'Ferramentas manuais'),
        ('FERRAM', 'FERRAM-ELET', N'Eletricas', N'Furadeiras e parafusadeiras'),
        ('FERRAM', 'FERRAM-SEG', N'Seguranca', N'EPIs e acessorios'),
        ('BRINQ', 'BRINQ-BEBE', N'Bebe', N'Brinquedos para primeira infancia'),
        ('BRINQ', 'BRINQ-JOGOS', N'Jogos', N'Jogos de tabuleiro e cartas'),
        ('BRINQ', 'BRINQ-EDU', N'Educativos', N'Aprendizado e criatividade'),
        ('AUTO', 'AUTO-INTER', N'Interior', N'Acessorios internos'),
        ('AUTO', 'AUTO-LIMPE', N'Limpeza', N'Cuidados e limpeza automotiva'),
        ('AUTO', 'AUTO-SEG', N'Seguranca viaria', N'Itens de seguranca'),
        ('PET', 'PET-ALIM', N'Alimentacao', N'Racoes e petiscos'),
        ('PET', 'PET-HIG', N'Higiene pet', N'Higiene e limpeza'),
        ('PET', 'PET-BRINQ', N'Brinquedos pet', N'Entretenimento para animais'),
        ('PAPEL', 'PAPEL-ESC', N'Escolar', N'Cadernos e mochilas'),
        ('PAPEL', 'PAPEL-ESCR', N'Escritorio', N'Itens de escritorio'),
        ('PAPEL', 'PAPEL-ART', N'Artes', N'Materiais artisticos')
) AS v(CategoryCode, SubcategoryCode, SubcategoryName, Description)
    ON v.CategoryCode = c.CategoryCode;

SELECT
    SubcategoryId,
    ROW_NUMBER() OVER (ORDER BY SubcategoryId) AS RowNum
INTO #SubcategoryMap
FROM sales.Subcategory;

CREATE UNIQUE CLUSTERED INDEX IX_SubcategoryMap_RowNum
    ON #SubcategoryMap(RowNum);

INSERT INTO sales.Brand (BrandCode, BrandName, WebsiteUrl, IsActive)
SELECT
    CONCAT('BR', RIGHT('000' + CAST(n.N AS VARCHAR(3)), 3)),
    CASE n.N
        WHEN 1 THEN N'Aurora'
        WHEN 2 THEN N'Nexa'
        WHEN 3 THEN N'Pulse'
        WHEN 4 THEN N'Vertex'
        WHEN 5 THEN N'Brisa'
        WHEN 6 THEN N'Orbit'
        WHEN 7 THEN N'Viva'
        WHEN 8 THEN N'Atlas'
        WHEN 9 THEN N'Lumina'
        WHEN 10 THEN N'Prisma'
        WHEN 11 THEN N'Sigma'
        WHEN 12 THEN N'NovaCasa'
        WHEN 13 THEN N'EcoLife'
        WHEN 14 THEN N'MaxPro'
        WHEN 15 THEN N'UrbanWay'
        WHEN 16 THEN N'PrimeTech'
        WHEN 17 THEN N'VerdeMais'
        WHEN 18 THEN N'Infinity'
        WHEN 19 THEN N'Delta'
        ELSE N'Solaris'
    END,
    CONCAT('https://www.marca', RIGHT('000' + CAST(n.N AS VARCHAR(3)), 3), '.example'),
    1
FROM #Numbers AS n
WHERE n.N <= 20;

SELECT
    BrandId,
    ROW_NUMBER() OVER (ORDER BY BrandId) AS RowNum
INTO #BrandMap
FROM sales.Brand;

CREATE UNIQUE CLUSTERED INDEX IX_BrandMap_RowNum
    ON #BrandMap(RowNum);

INSERT INTO sales.Supplier
(
    SupplierCode,
    SupplierName,
    TradeName,
    TaxDocument,
    ContactName,
    Email,
    Phone,
    CountryCode,
    StateCode,
    City,
    IsActive,
    CreatedAt,
    UpdatedAt
)
SELECT
    CONCAT('SUP', RIGHT('000' + CAST(n.N AS VARCHAR(3)), 3)),
    CONCAT(N'Fornecedor ', RIGHT('000' + CAST(n.N AS VARCHAR(3)), 3)),
    CONCAT(N'Forn ', RIGHT('000' + CAST(n.N AS VARCHAR(3)), 3)),
    RIGHT('00000000000000' + CAST(40000000000000 + n.N AS VARCHAR(20)), 14),
    CONCAT(N'Contato ', RIGHT('000' + CAST(n.N AS VARCHAR(3)), 3)),
    CONCAT('supplier', RIGHT('000' + CAST(n.N AS VARCHAR(3)), 3), '@demo.local'),
    CONCAT('+55 11 9', RIGHT('00000000' + CAST(20000000 + n.N * 17 AS VARCHAR(8)), 8)),
    'BR',
    CASE (n.N - 1) % 10
        WHEN 0 THEN 'SP'
        WHEN 1 THEN 'RJ'
        WHEN 2 THEN 'MG'
        WHEN 3 THEN 'PR'
        WHEN 4 THEN 'SC'
        WHEN 5 THEN 'RS'
        WHEN 6 THEN 'BA'
        WHEN 7 THEN 'GO'
        WHEN 8 THEN 'PE'
        ELSE 'CE'
    END,
    CASE (n.N - 1) % 10
        WHEN 0 THEN N'Sao Paulo'
        WHEN 1 THEN N'Rio de Janeiro'
        WHEN 2 THEN N'Belo Horizonte'
        WHEN 3 THEN N'Curitiba'
        WHEN 4 THEN N'Florianopolis'
        WHEN 5 THEN N'Porto Alegre'
        WHEN 6 THEN N'Salvador'
        WHEN 7 THEN N'Goiania'
        WHEN 8 THEN N'Recife'
        ELSE N'Fortaleza'
    END,
    1,
    DATEADD(DAY, -365 - (n.N * 9), CAST(@EndDate AS DATETIME2(0))),
    DATEADD(DAY, -60 - (n.N * 2), CAST(@EndDate AS DATETIME2(0)))
FROM #Numbers AS n
WHERE n.N <= 30;

SELECT
    SupplierId,
    ROW_NUMBER() OVER (ORDER BY SupplierId) AS RowNum
INTO #SupplierMap
FROM sales.Supplier;

CREATE UNIQUE CLUSTERED INDEX IX_SupplierMap_RowNum
    ON #SupplierMap(RowNum);

INSERT INTO sales.Product
(
    SKU,
    ProductName,
    SubcategoryId,
    SupplierId,
    BrandId,
    UnitPrice,
    CostPrice,
    UnitWeightKg,
    ReorderLevel,
    TargetStockLevel,
    LaunchDate,
    IsActive,
    CreatedAt,
    UpdatedAt
)
SELECT
    CONCAT('SKU-', RIGHT('000000' + CAST(n.N AS VARCHAR(6)), 6)),
    CONCAT(b.BrandName, N' ', s.SubcategoryName, N' ', RIGHT('000' + CAST(n.N AS VARCHAR(3)), 3)),
    s.SubcategoryId,
    sup.SupplierId,
    b.BrandId,
    CAST(ROUND(base.CostPrice * (1.28 + ((n.N % 12) / 100.0)), 2) AS DECIMAL(18,2)),
    CAST(ROUND(base.CostPrice, 2) AS DECIMAL(18,2)),
    CAST(ROUND(0.150 + ((n.N % 40) * 0.085), 3) AS DECIMAL(10,3)),
    10 + (n.N % 25),
    60 + (n.N % 120),
    DATEADD(DAY, -((n.N * 5) % 900), @EndDate),
    CASE WHEN n.N % 29 = 0 THEN 0 ELSE 1 END,
    DATEADD(DAY, -120 - (n.N % 360), CAST(@EndDate AS DATETIME2(0))),
    DATEADD(DAY, -10 - (n.N % 120), CAST(@EndDate AS DATETIME2(0)))
FROM #Numbers AS n
INNER JOIN #SubcategoryMap AS sm
    ON sm.RowNum = ((n.N - 1) % 36) + 1
INNER JOIN sales.Subcategory AS s
    ON s.SubcategoryId = sm.SubcategoryId
INNER JOIN #SupplierMap AS supm
    ON supm.RowNum = ((n.N - 1) % 30) + 1
INNER JOIN sales.Supplier AS sup
    ON sup.SupplierId = supm.SupplierId
INNER JOIN #BrandMap AS bm
    ON bm.RowNum = ((n.N - 1) % 20) + 1
INNER JOIN sales.Brand AS b
    ON b.BrandId = bm.BrandId
CROSS APPLY
(
    SELECT CAST(18 + ((n.N * 11) % 180) + (((n.N * 17) % 100) / 100.0) AS DECIMAL(18,2)) AS CostPrice
) AS base
WHERE n.N <= 400;

SELECT
    ProductId,
    ROW_NUMBER() OVER (ORDER BY ProductId) AS RowNum
INTO #ProductMap
FROM sales.Product;

CREATE UNIQUE CLUSTERED INDEX IX_ProductMap_RowNum
    ON #ProductMap(RowNum);

INSERT INTO sales.Customer
(
    CustomerCode,
    CustomerType,
    CustomerName,
    DocumentNumber,
    Email,
    Phone,
    BirthOrFoundationDate,
    RegistrationDate,
    LoyaltyTier,
    IsActive,
    CreatedAt,
    UpdatedAt
)
SELECT
    CONCAT('CUS', RIGHT('000000' + CAST(n.N AS VARCHAR(6)), 6)),
    CASE WHEN n.N % 10 = 0 THEN 'PJ' ELSE 'PF' END,
    CASE
        WHEN n.N % 10 = 0 THEN CONCAT(N'Empresa ', RIGHT('0000' + CAST(n.N AS VARCHAR(4)), 4), N' Ltda')
        ELSE CONCAT(N'Cliente ', RIGHT('0000' + CAST(n.N AS VARCHAR(4)), 4))
    END,
    CASE
        WHEN n.N % 10 = 0 THEN RIGHT('00000000000000' + CAST(50000000000000 + n.N AS VARCHAR(20)), 14)
        ELSE RIGHT('00000000000' + CAST(10000000000 + n.N AS VARCHAR(20)), 11)
    END,
    CONCAT('customer', RIGHT('000000' + CAST(n.N AS VARCHAR(6)), 6), '@demo.local'),
    CONCAT('+55 11 9', RIGHT('00000000' + CAST(30000000 + n.N * 23 AS VARCHAR(8)), 8)),
    CASE
        WHEN n.N % 10 = 0 THEN DATEADD(DAY, -(3650 + (n.N * 13) % 9000), @EndDate)
        ELSE DATEADD(DAY, -(6570 + (n.N * 17) % 12000), @EndDate)
    END,
    DATEADD(DAY, -((n.N * 7) % 420), @EndDate),
    CASE
        WHEN n.N % 17 = 0 THEN 'Gold'
        WHEN n.N % 5 = 0 THEN 'Silver'
        ELSE 'Standard'
    END,
    CASE WHEN n.N % 41 = 0 THEN 0 ELSE 1 END,
    DATEADD(DAY, -((n.N * 7) % 540), CAST(@EndDate AS DATETIME2(0))),
    DATEADD(DAY, -((n.N * 3) % 180), CAST(@EndDate AS DATETIME2(0)))
FROM #Numbers AS n
WHERE n.N <= 2000;

SELECT
    CustomerId,
    ROW_NUMBER() OVER (ORDER BY CustomerId) AS RowNum
INTO #CustomerMap
FROM sales.Customer;

CREATE UNIQUE CLUSTERED INDEX IX_CustomerMap_RowNum
    ON #CustomerMap(RowNum);

INSERT INTO sales.CustomerAddress
(
    CustomerId,
    AddressType,
    AddressLabel,
    Street,
    StreetNumber,
    Complement,
    Neighborhood,
    City,
    StateCode,
    PostalCode,
    CountryCode,
    IsPrimary,
    CreatedAt,
    UpdatedAt
)
SELECT
    c.CustomerId,
    'Shipping',
    N'Endereco principal',
    CONCAT(N'Rua ', RIGHT('0000' + CAST(cm.RowNum AS VARCHAR(4)), 4)),
    CAST(10 + (cm.RowNum % 900) AS NVARCHAR(20)),
    CASE WHEN cm.RowNum % 7 = 0 THEN N'Apto ' + CAST((cm.RowNum % 120) + 1 AS NVARCHAR(10)) ELSE NULL END,
    CONCAT(N'Bairro ', CHAR(65 + (cm.RowNum % 26))),
    CASE (cm.RowNum - 1) % 10
        WHEN 0 THEN N'Sao Paulo'
        WHEN 1 THEN N'Rio de Janeiro'
        WHEN 2 THEN N'Belo Horizonte'
        WHEN 3 THEN N'Curitiba'
        WHEN 4 THEN N'Campinas'
        WHEN 5 THEN N'Porto Alegre'
        WHEN 6 THEN N'Salvador'
        WHEN 7 THEN N'Goiania'
        WHEN 8 THEN N'Recife'
        ELSE N'Fortaleza'
    END,
    CASE (cm.RowNum - 1) % 10
        WHEN 0 THEN 'SP'
        WHEN 1 THEN 'RJ'
        WHEN 2 THEN 'MG'
        WHEN 3 THEN 'PR'
        WHEN 4 THEN 'SP'
        WHEN 5 THEN 'RS'
        WHEN 6 THEN 'BA'
        WHEN 7 THEN 'GO'
        WHEN 8 THEN 'PE'
        ELSE 'CE'
    END,
    CONCAT(RIGHT('00000' + CAST(10000 + cm.RowNum AS VARCHAR(5)), 5), '-', RIGHT('000' + CAST(cm.RowNum % 1000 AS VARCHAR(3)), 3)),
    'BR',
    1,
    DATEADD(DAY, -(cm.RowNum % 360), CAST(@EndDate AS DATETIME2(0))),
    DATEADD(DAY, -(cm.RowNum % 180), CAST(@EndDate AS DATETIME2(0)))
FROM #CustomerMap AS cm
INNER JOIN sales.Customer AS c
    ON c.CustomerId = cm.CustomerId;

INSERT INTO sales.CustomerAddress
(
    CustomerId,
    AddressType,
    AddressLabel,
    Street,
    StreetNumber,
    Complement,
    Neighborhood,
    City,
    StateCode,
    PostalCode,
    CountryCode,
    IsPrimary,
    CreatedAt,
    UpdatedAt
)
SELECT
    c.CustomerId,
    'Billing',
    N'Endereco faturamento',
    CONCAT(N'Avenida ', RIGHT('0000' + CAST(cm.RowNum AS VARCHAR(4)), 4)),
    CAST(100 + (cm.RowNum % 700) AS NVARCHAR(20)),
    CASE WHEN cm.RowNum % 9 = 0 THEN N'Sala ' + CAST((cm.RowNum % 50) + 1 AS NVARCHAR(10)) ELSE NULL END,
    CONCAT(N'Regiao ', CHAR(65 + (cm.RowNum % 26))),
    CASE (cm.RowNum - 1) % 10
        WHEN 0 THEN N'Sao Paulo'
        WHEN 1 THEN N'Rio de Janeiro'
        WHEN 2 THEN N'Belo Horizonte'
        WHEN 3 THEN N'Curitiba'
        WHEN 4 THEN N'Campinas'
        WHEN 5 THEN N'Porto Alegre'
        WHEN 6 THEN N'Salvador'
        WHEN 7 THEN N'Goiania'
        WHEN 8 THEN N'Recife'
        ELSE N'Fortaleza'
    END,
    CASE (cm.RowNum - 1) % 10
        WHEN 0 THEN 'SP'
        WHEN 1 THEN 'RJ'
        WHEN 2 THEN 'MG'
        WHEN 3 THEN 'PR'
        WHEN 4 THEN 'SP'
        WHEN 5 THEN 'RS'
        WHEN 6 THEN 'BA'
        WHEN 7 THEN 'GO'
        WHEN 8 THEN 'PE'
        ELSE 'CE'
    END,
    CONCAT(RIGHT('00000' + CAST(20000 + cm.RowNum AS VARCHAR(5)), 5), '-', RIGHT('000' + CAST((cm.RowNum * 3) % 1000 AS VARCHAR(3)), 3)),
    'BR',
    1,
    DATEADD(DAY, -(cm.RowNum % 300), CAST(@EndDate AS DATETIME2(0))),
    DATEADD(DAY, -(cm.RowNum % 150), CAST(@EndDate AS DATETIME2(0)))
FROM #CustomerMap AS cm
INNER JOIN sales.Customer AS c
    ON c.CustomerId = cm.CustomerId
WHERE cm.RowNum <= 1000;

INSERT INTO sales.SalesRep
(
    SalesRepCode,
    FullName,
    Email,
    Phone,
    HireDate,
    CommissionRate,
    IsActive,
    CreatedAt,
    UpdatedAt
)
SELECT
    CONCAT('REP', RIGHT('000' + CAST(n.N AS VARCHAR(3)), 3)),
    CONCAT(N'Vendedor ', RIGHT('000' + CAST(n.N AS VARCHAR(3)), 3)),
    CONCAT('rep', RIGHT('000' + CAST(n.N AS VARCHAR(3)), 3), '@demo.local'),
    CONCAT('+55 11 9', RIGHT('00000000' + CAST(60000000 + n.N * 19 AS VARCHAR(8)), 8)),
    DATEADD(DAY, -(1800 + n.N * 45), @EndDate),
    CAST(1.80 + (n.N % 5) * 0.35 AS DECIMAL(5,2)),
    1,
    DATEADD(DAY, -(1400 + n.N * 40), CAST(@EndDate AS DATETIME2(0))),
    DATEADD(DAY, -(30 + n.N), CAST(@EndDate AS DATETIME2(0)))
FROM #Numbers AS n
WHERE n.N <= 12;

SELECT
    SalesRepId,
    ROW_NUMBER() OVER (ORDER BY SalesRepId) AS RowNum
INTO #SalesRepMap
FROM sales.SalesRep;

CREATE UNIQUE CLUSTERED INDEX IX_SalesRepMap_RowNum
    ON #SalesRepMap(RowNum);

SELECT
    c.CustomerId,
    MAX(CASE WHEN ca.AddressType = 'Shipping' AND ca.IsPrimary = 1 THEN ca.CustomerAddressId END) AS ShippingAddressId,
    MAX(CASE WHEN ca.AddressType = 'Billing' AND ca.IsPrimary = 1 THEN ca.CustomerAddressId END) AS BillingAddressId
INTO #CustomerAddressChoice
FROM sales.Customer AS c
LEFT JOIN sales.CustomerAddress AS ca
    ON ca.CustomerId = c.CustomerId
GROUP BY c.CustomerId;

CREATE UNIQUE CLUSTERED INDEX IX_CustomerAddressChoice_CustomerId
    ON #CustomerAddressChoice(CustomerId);

DECLARE @OrderStatusPending INT = (SELECT OrderStatusId FROM sales.OrderStatus WHERE StatusCode = 'PENDING');
DECLARE @OrderStatusPaid INT = (SELECT OrderStatusId FROM sales.OrderStatus WHERE StatusCode = 'PAID');
DECLARE @OrderStatusPicking INT = (SELECT OrderStatusId FROM sales.OrderStatus WHERE StatusCode = 'PICKING');
DECLARE @OrderStatusShipped INT = (SELECT OrderStatusId FROM sales.OrderStatus WHERE StatusCode = 'SHIPPED');
DECLARE @OrderStatusDelivered INT = (SELECT OrderStatusId FROM sales.OrderStatus WHERE StatusCode = 'DELIVERED');
DECLARE @OrderStatusPartialReturn INT = (SELECT OrderStatusId FROM sales.OrderStatus WHERE StatusCode = 'PARTIALLY_RETURNED');
DECLARE @OrderStatusReturned INT = (SELECT OrderStatusId FROM sales.OrderStatus WHERE StatusCode = 'RETURNED');
DECLARE @OrderStatusCancelled INT = (SELECT OrderStatusId FROM sales.OrderStatus WHERE StatusCode = 'CANCELLED');

DECLARE @PaymentStatusPending INT = (SELECT PaymentStatusId FROM sales.PaymentStatus WHERE StatusCode = 'PENDING');
DECLARE @PaymentStatusPaid INT = (SELECT PaymentStatusId FROM sales.PaymentStatus WHERE StatusCode = 'PAID');
DECLARE @PaymentStatusFailed INT = (SELECT PaymentStatusId FROM sales.PaymentStatus WHERE StatusCode = 'FAILED');
DECLARE @PaymentStatusPartialRefund INT = (SELECT PaymentStatusId FROM sales.PaymentStatus WHERE StatusCode = 'PARTIALLY_REFUNDED');
DECLARE @PaymentStatusRefunded INT = (SELECT PaymentStatusId FROM sales.PaymentStatus WHERE StatusCode = 'REFUNDED');
DECLARE @PaymentMethodCash INT = (SELECT PaymentMethodId FROM sales.PaymentMethod WHERE MethodCode = 'CASH');
DECLARE @PaymentMethodBankTransfer INT = (SELECT PaymentMethodId FROM sales.PaymentMethod WHERE MethodCode = 'BANK_TRANSFER');
DECLARE @PaymentMethodCreditCard INT = (SELECT PaymentMethodId FROM sales.PaymentMethod WHERE MethodCode = 'CREDIT_CARD');

DECLARE @ShipmentStatusShipped INT = (SELECT ShipmentStatusId FROM sales.ShipmentStatus WHERE StatusCode = 'SHIPPED');
DECLARE @ShipmentStatusInTransit INT = (SELECT ShipmentStatusId FROM sales.ShipmentStatus WHERE StatusCode = 'IN_TRANSIT');
DECLARE @ShipmentStatusDelivered INT = (SELECT ShipmentStatusId FROM sales.ShipmentStatus WHERE StatusCode = 'DELIVERED');

DECLARE @ReturnStatusApproved INT = (SELECT ReturnStatusId FROM sales.ReturnStatus WHERE StatusCode = 'APPROVED');
DECLARE @ReturnStatusRefunded INT = (SELECT ReturnStatusId FROM sales.ReturnStatus WHERE StatusCode = 'REFUNDED');
DECLARE @MovementTypeInitial INT = (SELECT InventoryMovementTypeId FROM sales.InventoryMovementType WHERE MovementCode = 'INITIAL_STOCK');
DECLARE @MovementTypeSale INT = (SELECT InventoryMovementTypeId FROM sales.InventoryMovementType WHERE MovementCode = 'SALE_OUT');
DECLARE @MovementTypeReturn INT = (SELECT InventoryMovementTypeId FROM sales.InventoryMovementType WHERE MovementCode = 'RETURN_IN');

SELECT
    n.N AS SeedId,
    cm.CustomerId,
    scm.SalesChannelId,
    srm.SalesRepId,
    od.OrderDate,
    ac.ShippingAddressId,
    COALESCE(ac.BillingAddressId, ac.ShippingAddressId) AS BillingAddressId
INTO #OrderSeed
FROM #Numbers AS n
INNER JOIN #CustomerMap AS cm
    ON cm.RowNum = ((n.N * 37) % 2000) + 1
INNER JOIN #SalesChannelMap AS scm
    ON scm.RowNum = ((n.N * 17) % 4) + 1
INNER JOIN #SalesRepMap AS srm
    ON srm.RowNum = ((n.N * 11) % 12) + 1
INNER JOIN #CustomerAddressChoice AS ac
    ON ac.CustomerId = cm.CustomerId
CROSS APPLY
(
    SELECT CASE
        WHEN @EndDate >= '2025-11-01' AND n.N % 6 = 0 THEN
            CASE
                WHEN ABS(CHECKSUM(CONCAT('SEASON-M-', n.N))) % 2 = 0
                    THEN DATEADD(DAY, ABS(CHECKSUM(CONCAT('SEASON-D-', n.N))) % 30, CONVERT(DATE, '2025-11-01'))
                ELSE DATEADD(DAY, ABS(CHECKSUM(CONCAT('SEASON-D-', n.N))) % 31, CONVERT(DATE, '2025-12-01'))
            END
        ELSE DATEADD(DAY, ABS(CHECKSUM(CONCAT('ORD-DAY-', n.N))) % @TotalDays, @StartDate)
    END AS BaseDate
) AS rawd
CROSS APPLY
(
    SELECT CASE
        WHEN DATEDIFF(DAY, '19000101', rawd.BaseDate) % 7 = 5 THEN DATEADD(DAY, -1, rawd.BaseDate)
        WHEN DATEDIFF(DAY, '19000101', rawd.BaseDate) % 7 = 6 THEN
            CASE
                WHEN DATEADD(DAY, 1, rawd.BaseDate) <= @EndDate THEN DATEADD(DAY, 1, rawd.BaseDate)
                ELSE DATEADD(DAY, -2, rawd.BaseDate)
            END
        ELSE rawd.BaseDate
    END AS WorkdayDate
) AS wd
CROSS APPLY
(
    SELECT DATEADD(MINUTE, 480 + (ABS(CHECKSUM(CONCAT('ORD-TIME-', n.N))) % 660), CAST(wd.WorkdayDate AS DATETIME2(0))) AS OrderDate
) AS od
WHERE n.N <= 25000;

CREATE UNIQUE CLUSTERED INDEX IX_OrderSeed_SeedId
    ON #OrderSeed(SeedId);

INSERT INTO sales.SalesOrder
(
    OrderNumber,
    CustomerId,
    BillingAddressId,
    ShippingAddressId,
    SalesChannelId,
    SalesRepId,
    OrderStatusId,
    OrderDate,
    RequiredDate,
    ApprovedAt,
    CurrencyCode,
    Subtotal,
    DiscountAmount,
    ShippingAmount,
    TaxAmount,
    TotalAmount,
    Notes,
    CreatedAt,
    UpdatedAt
)
SELECT
    CONCAT('SO', RIGHT('00000000' + CAST(os.SeedId AS VARCHAR(8)), 8)),
    os.CustomerId,
    os.BillingAddressId,
    os.ShippingAddressId,
    os.SalesChannelId,
    os.SalesRepId,
    @OrderStatusPending,
    os.OrderDate,
    DATEADD(DAY, 2 + (os.SeedId % 7), CAST(os.OrderDate AS DATE)),
    NULL,
    'BRL',
    0,
    0,
    0,
    0,
    0,
    CONCAT(N'Pedido fake gerado para simulacao #', os.SeedId),
    os.OrderDate,
    os.OrderDate
FROM #OrderSeed AS os;

INSERT INTO sales.SalesOrderItem
(
    OrderId,
    LineNumber,
    ProductId,
    Quantity,
    UnitCost,
    UnitPrice,
    DiscountAmount,
    LineTotal,
    CreatedAt,
    UpdatedAt
)
SELECT
    o.OrderId,
    lines.LineNumber,
    prod.ProductId,
    calc.Quantity,
    prod.CostPrice,
    prod.UnitPrice,
    calc.DiscountAmount,
    calc.LineTotal,
    DATEADD(MINUTE, lines.LineNumber * 5, o.OrderDate),
    DATEADD(MINUTE, lines.LineNumber * 5, o.OrderDate)
FROM sales.SalesOrder AS o
CROSS APPLY
(
    SELECT 2 + (ABS(CHECKSUM(CONCAT('ITEMCOUNT-', o.OrderId))) % 4) AS ItemCount
) AS ic
CROSS APPLY
(
    SELECT v.LineNumber
    FROM (VALUES (1), (2), (3), (4), (5)) AS v(LineNumber)
    WHERE v.LineNumber <= ic.ItemCount
) AS lines
CROSS APPLY
(
    SELECT ((o.OrderId * 17 + lines.LineNumber * 23) % 400) + 1 AS ProductRowNum
) AS pid
INNER JOIN #ProductMap AS pm
    ON pm.RowNum = pid.ProductRowNum
INNER JOIN sales.Product AS prod
    ON prod.ProductId = pm.ProductId
CROSS APPLY
(
    SELECT
        1 + (ABS(CHECKSUM(CONCAT('QTY-', o.OrderId, '-', lines.LineNumber))) % 5) AS Quantity,
        CAST(
            ROUND(
                (1 + (ABS(CHECKSUM(CONCAT('QTY-', o.OrderId, '-', lines.LineNumber))) % 5)) * prod.UnitPrice
                * CASE
                    WHEN ABS(CHECKSUM(CONCAT('DISCFLAG-', o.OrderId, '-', lines.LineNumber))) % 100 < 27
                        THEN ((ABS(CHECKSUM(CONCAT('DISCRATE-', o.OrderId, '-', lines.LineNumber))) % 12) + 1) / 100.0
                    ELSE 0
                  END,
                2
            ) AS DECIMAL(18,2)
        ) AS DiscountAmount,
        CAST(
            ROUND(
                (1 + (ABS(CHECKSUM(CONCAT('QTY-', o.OrderId, '-', lines.LineNumber))) % 5)) * prod.UnitPrice
                - ROUND(
                    (1 + (ABS(CHECKSUM(CONCAT('QTY-', o.OrderId, '-', lines.LineNumber))) % 5)) * prod.UnitPrice
                    * CASE
                        WHEN ABS(CHECKSUM(CONCAT('DISCFLAG-', o.OrderId, '-', lines.LineNumber))) % 100 < 27
                            THEN ((ABS(CHECKSUM(CONCAT('DISCRATE-', o.OrderId, '-', lines.LineNumber))) % 12) + 1) / 100.0
                        ELSE 0
                      END,
                    2
                ),
                2
            ) AS DECIMAL(18,2)
        ) AS LineTotal
) AS calc;

WITH OrderTotals AS
(
    SELECT
        soi.OrderId,
        CAST(ROUND(SUM(soi.Quantity * soi.UnitPrice), 2) AS DECIMAL(18,2)) AS GrossSubtotal,
        CAST(ROUND(SUM(soi.DiscountAmount), 2) AS DECIMAL(18,2)) AS TotalDiscount
    FROM sales.SalesOrderItem AS soi
    GROUP BY soi.OrderId
)
UPDATE o
SET
    o.Subtotal = t.GrossSubtotal,
    o.DiscountAmount = t.TotalDiscount,
    o.ShippingAmount = shippingcalc.ShippingAmount,
    o.TaxAmount = 0,
    o.TotalAmount = CAST(ROUND(t.GrossSubtotal - t.TotalDiscount + shippingcalc.ShippingAmount, 2) AS DECIMAL(18,2)),
    o.UpdatedAt = DATEADD(MINUTE, 15, o.OrderDate)
FROM sales.SalesOrder AS o
INNER JOIN OrderTotals AS t
    ON t.OrderId = o.OrderId
INNER JOIN sales.SalesChannel AS ch
    ON ch.SalesChannelId = o.SalesChannelId
CROSS APPLY
(
    SELECT CAST
    (
        CASE
            WHEN ch.ChannelCode = 'STORE' THEN 0
            WHEN t.GrossSubtotal >= 600 THEN 0
            ELSE 12 + ((o.OrderId % 6) * 4)
        END AS DECIMAL(18,2)
    ) AS ShippingAmount
) AS shippingcalc;

INSERT INTO sales.Payment
(
    OrderId,
    PaymentMethodId,
    PaymentStatusId,
    PaymentDate,
    Amount,
    InstallmentCount,
    PaymentReference,
    Notes,
    CreatedAt,
    UpdatedAt
)
SELECT
    o.OrderId,
    paychoice.SelectedPaymentMethodId,
    CASE
        WHEN ABS(CHECKSUM(CONCAT('PAYFAIL-', o.OrderId))) % 100 < 3 THEN @PaymentStatusFailed
        WHEN CAST(o.OrderDate AS DATE) >= DATEADD(DAY, -4, @EndDate) AND ABS(CHECKSUM(CONCAT('PAYPEND-', o.OrderId))) % 100 < 35 THEN @PaymentStatusPending
        ELSE @PaymentStatusPaid
    END,
    DATEADD(HOUR, 1 + (ABS(CHECKSUM(CONCAT('PAYHOUR-', o.OrderId))) % 36), o.OrderDate),
    o.TotalAmount,
    CASE
        WHEN paychoice.SelectedPaymentMethodId = @PaymentMethodCreditCard THEN 1 + (o.OrderId % 6)
        ELSE 1
    END,
    CONCAT('PAY', RIGHT('00000000' + CAST(o.OrderId AS VARCHAR(8)), 8)),
    N'Pagamento fake gerado para simulacao',
    DATEADD(HOUR, 1, o.OrderDate),
    DATEADD(HOUR, 2, o.OrderDate)
FROM sales.SalesOrder AS o
INNER JOIN sales.SalesChannel AS ch
    ON ch.SalesChannelId = o.SalesChannelId
INNER JOIN #PaymentMethodMap AS pmm
    ON pmm.RowNum = ((o.OrderId * 7) % 6) + 1
CROSS APPLY
(
    SELECT CASE
        WHEN ch.ChannelCode = 'STORE' AND o.OrderId % 4 = 0 THEN @PaymentMethodCash
        WHEN ch.ChannelCode = 'PHONE' AND o.OrderId % 5 = 0 THEN @PaymentMethodBankTransfer
        ELSE pmm.PaymentMethodId
    END AS SelectedPaymentMethodId
) AS paychoice;

UPDATE o
SET
    o.ApprovedAt = CASE WHEN p.PaymentStatusId = @PaymentStatusPaid THEN p.PaymentDate ELSE NULL END,
    o.UpdatedAt = DATEADD(HOUR, 2, o.OrderDate)
FROM sales.SalesOrder AS o
INNER JOIN sales.Payment AS p
    ON p.OrderId = o.OrderId;

WITH EligibleShipmentOrders AS
(
    SELECT TOP (22000)
        o.OrderId,
        o.OrderDate,
        o.ShippingAmount
    FROM sales.SalesOrder AS o
    INNER JOIN sales.Payment AS p
        ON p.OrderId = o.OrderId
    WHERE p.PaymentStatusId = @PaymentStatusPaid
      AND CAST(o.OrderDate AS DATE) <= DATEADD(DAY, -1, @EndDate)
    ORDER BY o.OrderDate, o.OrderId
)
INSERT INTO sales.Shipment
(
    OrderId,
    ShipmentNumber,
    ShipmentCarrierId,
    ShipmentStatusId,
    TrackingCode,
    ShippedAt,
    EstimatedDeliveryDate,
    DeliveredAt,
    FreightAmount,
    CreatedAt,
    UpdatedAt
)
SELECT
    eso.OrderId,
    CONCAT('SHP', RIGHT('00000000' + CAST(ROW_NUMBER() OVER (ORDER BY eso.OrderId) AS VARCHAR(8)), 8)),
    carrier.ShipmentCarrierId,
    CASE
        WHEN delivery.DeliveredAt IS NOT NULL THEN @ShipmentStatusDelivered
        WHEN CAST(ship.ShippedAt AS DATE) < @EndDate THEN @ShipmentStatusInTransit
        ELSE @ShipmentStatusShipped
    END,
    CONCAT('TRK', RIGHT('0000000000' + CAST(eso.OrderId AS VARCHAR(10)), 10)),
    ship.ShippedAt,
    delivery.EstimatedDeliveryDate,
    delivery.DeliveredAt,
    eso.ShippingAmount,
    ship.ShippedAt,
    COALESCE(delivery.DeliveredAt, ship.ShippedAt)
FROM EligibleShipmentOrders AS eso
INNER JOIN #ShipmentCarrierMap AS carrier
    ON carrier.RowNum = ((eso.OrderId * 7) % 6) + 1
CROSS APPLY
(
    SELECT
        CASE
            WHEN DATEADD(DAY, ABS(CHECKSUM(CONCAT('SHIPLAG-', eso.OrderId))) % 4, eso.OrderDate) > DATEADD(HOUR, 22, CAST(@EndDate AS DATETIME2(0)))
                THEN DATEADD(HOUR, 18, CAST(@EndDate AS DATETIME2(0)))
            ELSE DATEADD(DAY, ABS(CHECKSUM(CONCAT('SHIPLAG-', eso.OrderId))) % 4, eso.OrderDate)
        END AS ShippedAt
) AS ship
CROSS APPLY
(
    SELECT
        DATEADD(DAY, 2 + (ABS(CHECKSUM(CONCAT('ESTLAG-', eso.OrderId))) % 6), CAST(ship.ShippedAt AS DATE)) AS EstimatedDeliveryDate,
        CASE
            WHEN ABS(CHECKSUM(CONCAT('DELPROB-', eso.OrderId))) % 100 < 88
                 AND DATEADD(DAY, 2 + (ABS(CHECKSUM(CONCAT('DELLAG-', eso.OrderId))) % 7), ship.ShippedAt) <= DATEADD(HOUR, 22, CAST(@EndDate AS DATETIME2(0)))
                THEN DATEADD(DAY, 2 + (ABS(CHECKSUM(CONCAT('DELLAG-', eso.OrderId))) % 7), ship.ShippedAt)
            ELSE NULL
        END AS DeliveredAt
) AS delivery;

WITH DeliveredOrders AS
(
    SELECT TOP (1200)
        o.OrderId,
        o.CustomerId,
        s.DeliveredAt
    FROM sales.SalesOrder AS o
    INNER JOIN sales.Shipment AS s
        ON s.OrderId = o.OrderId
    WHERE s.ShipmentStatusId = @ShipmentStatusDelivered
      AND CAST(s.DeliveredAt AS DATE) <= DATEADD(DAY, -2, @EndDate)
    ORDER BY ABS(CHECKSUM(CONCAT('RETSEL-', o.OrderId))), o.OrderId
)
INSERT INTO sales.ReturnHeader
(
    ReturnNumber,
    OrderId,
    CustomerId,
    ReturnReasonId,
    ReturnStatusId,
    RequestedAt,
    ApprovedAt,
    CompletedAt,
    RefundAmount,
    Notes,
    CreatedAt,
    UpdatedAt
)
SELECT
    CONCAT('RET', RIGHT('00000000' + CAST(ROW_NUMBER() OVER (ORDER BY d.OrderId) AS VARCHAR(8)), 8)),
    d.OrderId,
    d.CustomerId,
    reason.ReturnReasonId,
    CASE WHEN timelines.CompletedAt IS NOT NULL THEN @ReturnStatusRefunded ELSE @ReturnStatusApproved END,
    timelines.RequestedAt,
    timelines.ApprovedAt,
    timelines.CompletedAt,
    0,
    N'Devolucao fake gerada para simulacao',
    timelines.RequestedAt,
    COALESCE(timelines.CompletedAt, timelines.ApprovedAt, timelines.RequestedAt)
FROM DeliveredOrders AS d
INNER JOIN #ReturnReasonMap AS reason
    ON reason.RowNum = ((d.OrderId * 5) % 6) + 1
CROSS APPLY
(
    SELECT DATEADD(DAY, 3 + (ABS(CHECKSUM(CONCAT('RETREQ-', d.OrderId))) % 25), d.DeliveredAt) AS RequestedRaw
) AS rawtimes
CROSS APPLY
(
    SELECT
        CASE
            WHEN rawtimes.RequestedRaw > DATEADD(HOUR, 20, CAST(@EndDate AS DATETIME2(0))) THEN DATEADD(HOUR, 20, CAST(@EndDate AS DATETIME2(0)))
            ELSE rawtimes.RequestedRaw
        END AS RequestedAt
) AS rq
CROSS APPLY
(
    SELECT
        CASE
            WHEN DATEADD(DAY, 1 + (ABS(CHECKSUM(CONCAT('RETAPP-', d.OrderId))) % 3), rq.RequestedAt) <= DATEADD(HOUR, 21, CAST(@EndDate AS DATETIME2(0)))
                THEN DATEADD(DAY, 1 + (ABS(CHECKSUM(CONCAT('RETAPP-', d.OrderId))) % 3), rq.RequestedAt)
            ELSE DATEADD(HOUR, 21, CAST(@EndDate AS DATETIME2(0)))
        END AS ApprovedAt
) AS ap
CROSS APPLY
(
    SELECT
        rq.RequestedAt,
        ap.ApprovedAt,
        CASE
            WHEN ABS(CHECKSUM(CONCAT('RETDONE-', d.OrderId))) % 100 < 82
                 AND DATEADD(DAY, 1 + (ABS(CHECKSUM(CONCAT('RETCOMP-', d.OrderId))) % 5), ap.ApprovedAt) <= DATEADD(HOUR, 22, CAST(@EndDate AS DATETIME2(0)))
                THEN DATEADD(DAY, 1 + (ABS(CHECKSUM(CONCAT('RETCOMP-', d.OrderId))) % 5), ap.ApprovedAt)
            ELSE NULL
        END AS CompletedAt
) AS timelines;

WITH RankedOrderItems AS
(
    SELECT
        rh.ReturnId,
        soi.OrderItemId,
        soi.Quantity,
        CAST(ROUND(soi.LineTotal / NULLIF(soi.Quantity, 0), 2) AS DECIMAL(18,2)) AS UnitRefundAmount,
        ROW_NUMBER() OVER (PARTITION BY rh.ReturnId ORDER BY ABS(CHECKSUM(CONCAT('RETITEM-', soi.OrderItemId))), soi.OrderItemId) AS ItemRank
    FROM sales.ReturnHeader AS rh
    INNER JOIN sales.SalesOrderItem AS soi
        ON soi.OrderId = rh.OrderId
)
INSERT INTO sales.ReturnItem
(
    ReturnId,
    OrderItemId,
    QuantityReturned,
    UnitRefundAmount,
    LineRefundAmount,
    CreatedAt,
    UpdatedAt
)
SELECT
    roi.ReturnId,
    roi.OrderItemId,
    qty.QuantityReturned,
    roi.UnitRefundAmount,
    CAST(ROUND(qty.QuantityReturned * roi.UnitRefundAmount, 2) AS DECIMAL(18,2)),
    rh.RequestedAt,
    COALESCE(rh.CompletedAt, rh.ApprovedAt, rh.RequestedAt)
FROM RankedOrderItems AS roi
INNER JOIN sales.ReturnHeader AS rh
    ON rh.ReturnId = roi.ReturnId
CROSS APPLY
(
    SELECT CASE
        WHEN roi.Quantity = 1 THEN 1
        ELSE 1 + (ABS(CHECKSUM(CONCAT('RETQTY-', roi.OrderItemId))) % roi.Quantity)
    END AS QuantityReturned
) AS qty
WHERE roi.ItemRank = 1;

WITH RefundTotals AS
(
    SELECT
        ri.ReturnId,
        CAST(ROUND(SUM(ri.LineRefundAmount), 2) AS DECIMAL(18,2)) AS RefundAmount
    FROM sales.ReturnItem AS ri
    GROUP BY ri.ReturnId
)
UPDATE rh
SET
    rh.RefundAmount = rt.RefundAmount,
    rh.UpdatedAt = COALESCE(rh.CompletedAt, rh.ApprovedAt, rh.RequestedAt)
FROM sales.ReturnHeader AS rh
INNER JOIN RefundTotals AS rt
    ON rt.ReturnId = rh.ReturnId;

WITH CompletedRefunds AS
(
    SELECT
        rh.OrderId,
        SUM(rh.RefundAmount) AS RefundAmount
    FROM sales.ReturnHeader AS rh
    WHERE rh.ReturnStatusId = @ReturnStatusRefunded
    GROUP BY rh.OrderId
)
UPDATE p
SET
    p.PaymentStatusId = CASE
        WHEN cr.RefundAmount >= o.TotalAmount - 0.01 THEN @PaymentStatusRefunded
        ELSE @PaymentStatusPartialRefund
    END,
    p.UpdatedAt = COALESCE(lastrefund.LastCompletedAt, p.UpdatedAt)
FROM sales.Payment AS p
INNER JOIN sales.SalesOrder AS o
    ON o.OrderId = p.OrderId
INNER JOIN CompletedRefunds AS cr
    ON cr.OrderId = p.OrderId
CROSS APPLY
(
    SELECT MAX(rh.CompletedAt) AS LastCompletedAt
    FROM sales.ReturnHeader AS rh
    WHERE rh.OrderId = p.OrderId
      AND rh.ReturnStatusId = @ReturnStatusRefunded
) AS lastrefund;

UPDATE o
SET
    o.OrderStatusId = CASE
        WHEN p.PaymentStatusId = @PaymentStatusFailed THEN @OrderStatusCancelled
        WHEN p.PaymentStatusId = @PaymentStatusPending THEN @OrderStatusPending
        WHEN s.ShipmentId IS NULL AND CAST(o.OrderDate AS DATE) >= DATEADD(DAY, -3, @EndDate) THEN @OrderStatusPaid
        WHEN s.ShipmentId IS NULL THEN @OrderStatusPicking
        WHEN s.ShipmentStatusId IN (@ShipmentStatusShipped, @ShipmentStatusInTransit) THEN @OrderStatusShipped
        WHEN rt.CompletedRefundAmount IS NOT NULL AND rt.CompletedRefundAmount >= o.TotalAmount - 0.01 THEN @OrderStatusReturned
        WHEN rt.CompletedRefundAmount IS NOT NULL THEN @OrderStatusPartialReturn
        WHEN s.ShipmentStatusId = @ShipmentStatusDelivered THEN @OrderStatusDelivered
        ELSE @OrderStatusPicking
    END,
    o.UpdatedAt = DATEADD(HOUR, 3, o.OrderDate)
FROM sales.SalesOrder AS o
INNER JOIN sales.Payment AS p
    ON p.OrderId = o.OrderId
LEFT JOIN sales.Shipment AS s
    ON s.OrderId = o.OrderId
LEFT JOIN
(
    SELECT
        rh.OrderId,
        SUM(rh.RefundAmount) AS CompletedRefundAmount
    FROM sales.ReturnHeader AS rh
    WHERE rh.ReturnStatusId = @ReturnStatusRefunded
    GROUP BY rh.OrderId
) AS rt
    ON rt.OrderId = o.OrderId;

WITH ShippedQuantity AS
(
    SELECT
        soi.ProductId,
        SUM(soi.Quantity) AS ShippedQty
    FROM sales.SalesOrderItem AS soi
    INNER JOIN sales.Shipment AS s
        ON s.OrderId = soi.OrderId
    GROUP BY soi.ProductId
)
INSERT INTO sales.InventoryMovement
(
    ProductId,
    InventoryMovementTypeId,
    SupplierId,
    OrderItemId,
    ReturnItemId,
    MovementDate,
    QuantityChange,
    UnitCost,
    ReferenceNote,
    CreatedAt
)
SELECT
    p.ProductId,
    @MovementTypeInitial,
    p.SupplierId,
    NULL,
    NULL,
    DATEADD(DAY, -30 - (pm.RowNum % 45), CAST(@StartDate AS DATETIME2(0))),
    ISNULL(sq.ShippedQty, 0) + 40 + (pm.RowNum % 120),
    p.CostPrice,
    N'Estoque inicial simulado',
    DATEADD(DAY, -30 - (pm.RowNum % 45), CAST(@StartDate AS DATETIME2(0)))
FROM sales.Product AS p
INNER JOIN #ProductMap AS pm
    ON pm.ProductId = p.ProductId
LEFT JOIN ShippedQuantity AS sq
    ON sq.ProductId = p.ProductId;

INSERT INTO sales.InventoryMovement
(
    ProductId,
    InventoryMovementTypeId,
    SupplierId,
    OrderItemId,
    ReturnItemId,
    MovementDate,
    QuantityChange,
    UnitCost,
    ReferenceNote,
    CreatedAt
)
SELECT
    soi.ProductId,
    @MovementTypeSale,
    NULL,
    soi.OrderItemId,
    NULL,
    s.ShippedAt,
    -soi.Quantity,
    soi.UnitCost,
    CONCAT(N'Saida de estoque do pedido ', o.OrderNumber),
    s.ShippedAt
FROM sales.SalesOrderItem AS soi
INNER JOIN sales.SalesOrder AS o
    ON o.OrderId = soi.OrderId
INNER JOIN sales.Shipment AS s
    ON s.OrderId = soi.OrderId;

INSERT INTO sales.InventoryMovement
(
    ProductId,
    InventoryMovementTypeId,
    SupplierId,
    OrderItemId,
    ReturnItemId,
    MovementDate,
    QuantityChange,
    UnitCost,
    ReferenceNote,
    CreatedAt
)
SELECT
    soi.ProductId,
    @MovementTypeReturn,
    NULL,
    soi.OrderItemId,
    ri.ReturnItemId,
    rh.CompletedAt,
    ri.QuantityReturned,
    soi.UnitCost,
    CONCAT(N'Retorno da devolucao ', rh.ReturnNumber),
    rh.CompletedAt
FROM sales.ReturnItem AS ri
INNER JOIN sales.ReturnHeader AS rh
    ON rh.ReturnId = ri.ReturnId
INNER JOIN sales.SalesOrderItem AS soi
    ON soi.OrderItemId = ri.OrderItemId
WHERE rh.CompletedAt IS NOT NULL;

DROP TABLE #OrderSeed;
DROP TABLE #CustomerAddressChoice;
DROP TABLE #SalesRepMap;
DROP TABLE #CustomerMap;
DROP TABLE #ProductMap;
DROP TABLE #SupplierMap;
DROP TABLE #BrandMap;
DROP TABLE #SubcategoryMap;
DROP TABLE #ReturnReasonMap;
DROP TABLE #ShipmentCarrierMap;
DROP TABLE #SalesChannelMap;
DROP TABLE #PaymentMethodMap;
DROP TABLE #Numbers;

COMMIT TRANSACTION;

SELECT
    CAST(@StartDate AS DATE) AS SeedStartDate,
    CAST(@EndDate AS DATE) AS SeedEndDate,
    (SELECT COUNT(*) FROM sales.SalesOrder) AS OrdersCreated,
    (SELECT COUNT(*) FROM sales.SalesOrderItem) AS OrderItemsCreated,
    (SELECT COUNT(*) FROM sales.Payment) AS PaymentsCreated,
    (SELECT COUNT(*) FROM sales.Shipment) AS ShipmentsCreated,
    (SELECT COUNT(*) FROM sales.ReturnHeader) AS ReturnsCreated,
    (SELECT COUNT(*) FROM sales.InventoryMovement) AS InventoryMovementsCreated;
