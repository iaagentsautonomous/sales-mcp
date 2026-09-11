SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE A2A;
GO

IF SCHEMA_ID(N'sales') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA sales AUTHORIZATION dbo;');
END;
GO

IF OBJECT_ID(N'sales.InventoryMovement', N'U') IS NOT NULL DROP TABLE sales.InventoryMovement;
IF OBJECT_ID(N'sales.ReturnItem', N'U') IS NOT NULL DROP TABLE sales.ReturnItem;
IF OBJECT_ID(N'sales.ReturnHeader', N'U') IS NOT NULL DROP TABLE sales.ReturnHeader;
IF OBJECT_ID(N'sales.Shipment', N'U') IS NOT NULL DROP TABLE sales.Shipment;
IF OBJECT_ID(N'sales.Payment', N'U') IS NOT NULL DROP TABLE sales.Payment;
IF OBJECT_ID(N'sales.SalesOrderItem', N'U') IS NOT NULL DROP TABLE sales.SalesOrderItem;
IF OBJECT_ID(N'sales.SalesOrder', N'U') IS NOT NULL DROP TABLE sales.SalesOrder;
IF OBJECT_ID(N'sales.CustomerAddress', N'U') IS NOT NULL DROP TABLE sales.CustomerAddress;
IF OBJECT_ID(N'sales.Product', N'U') IS NOT NULL DROP TABLE sales.Product;
IF OBJECT_ID(N'sales.Subcategory', N'U') IS NOT NULL DROP TABLE sales.Subcategory;
IF OBJECT_ID(N'sales.Category', N'U') IS NOT NULL DROP TABLE sales.Category;
IF OBJECT_ID(N'sales.Supplier', N'U') IS NOT NULL DROP TABLE sales.Supplier;
IF OBJECT_ID(N'sales.Brand', N'U') IS NOT NULL DROP TABLE sales.Brand;
IF OBJECT_ID(N'sales.Customer', N'U') IS NOT NULL DROP TABLE sales.Customer;
IF OBJECT_ID(N'sales.SalesChannel', N'U') IS NOT NULL DROP TABLE sales.SalesChannel;
IF OBJECT_ID(N'sales.SalesRep', N'U') IS NOT NULL DROP TABLE sales.SalesRep;
IF OBJECT_ID(N'sales.OrderStatus', N'U') IS NOT NULL DROP TABLE sales.OrderStatus;
IF OBJECT_ID(N'sales.PaymentMethod', N'U') IS NOT NULL DROP TABLE sales.PaymentMethod;
IF OBJECT_ID(N'sales.PaymentStatus', N'U') IS NOT NULL DROP TABLE sales.PaymentStatus;
IF OBJECT_ID(N'sales.ShipmentCarrier', N'U') IS NOT NULL DROP TABLE sales.ShipmentCarrier;
IF OBJECT_ID(N'sales.ShipmentStatus', N'U') IS NOT NULL DROP TABLE sales.ShipmentStatus;
IF OBJECT_ID(N'sales.ReturnReason', N'U') IS NOT NULL DROP TABLE sales.ReturnReason;
IF OBJECT_ID(N'sales.ReturnStatus', N'U') IS NOT NULL DROP TABLE sales.ReturnStatus;
IF OBJECT_ID(N'sales.InventoryMovementType', N'U') IS NOT NULL DROP TABLE sales.InventoryMovementType;
GO

CREATE TABLE sales.Category
(
    CategoryId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_Category PRIMARY KEY,
    CategoryCode VARCHAR(20) NOT NULL,
    CategoryName NVARCHAR(120) NOT NULL,
    Description NVARCHAR(300) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_sales_Category_IsActive DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Category_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Category_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_sales_Category_Code UNIQUE (CategoryCode),
    CONSTRAINT UQ_sales_Category_Name UNIQUE (CategoryName)
);
GO

CREATE TABLE sales.Subcategory
(
    SubcategoryId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_Subcategory PRIMARY KEY,
    CategoryId INT NOT NULL,
    SubcategoryCode VARCHAR(24) NOT NULL,
    SubcategoryName NVARCHAR(120) NOT NULL,
    Description NVARCHAR(300) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_sales_Subcategory_IsActive DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Subcategory_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Subcategory_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_sales_Subcategory_Category FOREIGN KEY (CategoryId) REFERENCES sales.Category(CategoryId),
    CONSTRAINT UQ_sales_Subcategory_Code UNIQUE (SubcategoryCode),
    CONSTRAINT UQ_sales_Subcategory_Name UNIQUE (CategoryId, SubcategoryName)
);
GO

CREATE TABLE sales.Supplier
(
    SupplierId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_Supplier PRIMARY KEY,
    SupplierCode VARCHAR(20) NOT NULL,
    SupplierName NVARCHAR(160) NOT NULL,
    TradeName NVARCHAR(160) NULL,
    TaxDocument VARCHAR(18) NOT NULL,
    ContactName NVARCHAR(120) NULL,
    Email VARCHAR(160) NULL,
    Phone VARCHAR(30) NULL,
    CountryCode CHAR(2) NOT NULL CONSTRAINT DF_sales_Supplier_CountryCode DEFAULT ('BR'),
    StateCode CHAR(2) NOT NULL,
    City NVARCHAR(120) NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_sales_Supplier_IsActive DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Supplier_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Supplier_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_sales_Supplier_Code UNIQUE (SupplierCode),
    CONSTRAINT UQ_sales_Supplier_TaxDocument UNIQUE (TaxDocument)
);
GO

CREATE UNIQUE INDEX UX_sales_Supplier_Email
    ON sales.Supplier(Email)
    WHERE Email IS NOT NULL;
GO

CREATE TABLE sales.Brand
(
    BrandId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_Brand PRIMARY KEY,
    BrandCode VARCHAR(20) NOT NULL,
    BrandName NVARCHAR(120) NOT NULL,
    WebsiteUrl VARCHAR(200) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_sales_Brand_IsActive DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Brand_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Brand_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_sales_Brand_Code UNIQUE (BrandCode),
    CONSTRAINT UQ_sales_Brand_Name UNIQUE (BrandName)
);
GO

CREATE TABLE sales.Product
(
    ProductId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_Product PRIMARY KEY,
    SKU VARCHAR(30) NOT NULL,
    ProductName NVARCHAR(180) NOT NULL,
    SubcategoryId INT NOT NULL,
    SupplierId INT NOT NULL,
    BrandId INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    CostPrice DECIMAL(18,2) NOT NULL,
    UnitWeightKg DECIMAL(10,3) NULL,
    ReorderLevel INT NOT NULL CONSTRAINT DF_sales_Product_ReorderLevel DEFAULT (10),
    TargetStockLevel INT NOT NULL CONSTRAINT DF_sales_Product_TargetStockLevel DEFAULT (50),
    LaunchDate DATE NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_sales_Product_IsActive DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Product_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Product_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_sales_Product_Subcategory FOREIGN KEY (SubcategoryId) REFERENCES sales.Subcategory(SubcategoryId),
    CONSTRAINT FK_sales_Product_Supplier FOREIGN KEY (SupplierId) REFERENCES sales.Supplier(SupplierId),
    CONSTRAINT FK_sales_Product_Brand FOREIGN KEY (BrandId) REFERENCES sales.Brand(BrandId),
    CONSTRAINT UQ_sales_Product_SKU UNIQUE (SKU),
    CONSTRAINT CK_sales_Product_Prices CHECK (UnitPrice >= 0 AND CostPrice >= 0 AND UnitPrice >= CostPrice),
    CONSTRAINT CK_sales_Product_StockTargets CHECK (ReorderLevel >= 0 AND TargetStockLevel >= ReorderLevel)
);
GO

CREATE TABLE sales.Customer
(
    CustomerId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_Customer PRIMARY KEY,
    CustomerCode VARCHAR(20) NOT NULL,
    CustomerType CHAR(2) NOT NULL,
    CustomerName NVARCHAR(160) NOT NULL,
    DocumentNumber VARCHAR(18) NOT NULL,
    Email VARCHAR(160) NULL,
    Phone VARCHAR(30) NULL,
    BirthOrFoundationDate DATE NULL,
    RegistrationDate DATE NOT NULL,
    LoyaltyTier VARCHAR(20) NOT NULL CONSTRAINT DF_sales_Customer_LoyaltyTier DEFAULT ('Standard'),
    IsActive BIT NOT NULL CONSTRAINT DF_sales_Customer_IsActive DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Customer_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Customer_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_sales_Customer_Code UNIQUE (CustomerCode),
    CONSTRAINT UQ_sales_Customer_Document UNIQUE (DocumentNumber),
    CONSTRAINT CK_sales_Customer_Type CHECK (CustomerType IN ('PF', 'PJ'))
);
GO

CREATE UNIQUE INDEX UX_sales_Customer_Email
    ON sales.Customer(Email)
    WHERE Email IS NOT NULL;
GO

CREATE TABLE sales.CustomerAddress
(
    CustomerAddressId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_CustomerAddress PRIMARY KEY,
    CustomerId INT NOT NULL,
    AddressType VARCHAR(20) NOT NULL,
    AddressLabel NVARCHAR(80) NULL,
    Street NVARCHAR(160) NOT NULL,
    StreetNumber NVARCHAR(20) NOT NULL,
    Complement NVARCHAR(80) NULL,
    Neighborhood NVARCHAR(120) NULL,
    City NVARCHAR(120) NOT NULL,
    StateCode CHAR(2) NOT NULL,
    PostalCode VARCHAR(12) NOT NULL,
    CountryCode CHAR(2) NOT NULL CONSTRAINT DF_sales_CustomerAddress_CountryCode DEFAULT ('BR'),
    IsPrimary BIT NOT NULL CONSTRAINT DF_sales_CustomerAddress_IsPrimary DEFAULT (0),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_CustomerAddress_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_CustomerAddress_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_sales_CustomerAddress_Customer FOREIGN KEY (CustomerId) REFERENCES sales.Customer(CustomerId),
    CONSTRAINT CK_sales_CustomerAddress_Type CHECK (AddressType IN ('Shipping', 'Billing', 'Other'))
);
GO

CREATE TABLE sales.SalesChannel
(
    SalesChannelId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_SalesChannel PRIMARY KEY,
    ChannelCode VARCHAR(20) NOT NULL,
    ChannelName NVARCHAR(120) NOT NULL,
    Description NVARCHAR(240) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_sales_SalesChannel_IsActive DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_SalesChannel_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_SalesChannel_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_sales_SalesChannel_Code UNIQUE (ChannelCode),
    CONSTRAINT UQ_sales_SalesChannel_Name UNIQUE (ChannelName)
);
GO

CREATE TABLE sales.SalesRep
(
    SalesRepId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_SalesRep PRIMARY KEY,
    SalesRepCode VARCHAR(20) NOT NULL,
    FullName NVARCHAR(160) NOT NULL,
    Email VARCHAR(160) NOT NULL,
    Phone VARCHAR(30) NULL,
    HireDate DATE NOT NULL,
    CommissionRate DECIMAL(5,2) NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_sales_SalesRep_IsActive DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_SalesRep_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_SalesRep_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_sales_SalesRep_Code UNIQUE (SalesRepCode),
    CONSTRAINT UQ_sales_SalesRep_Email UNIQUE (Email),
    CONSTRAINT CK_sales_SalesRep_Commission CHECK (CommissionRate >= 0 AND CommissionRate <= 100)
);
GO

CREATE TABLE sales.OrderStatus
(
    OrderStatusId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_OrderStatus PRIMARY KEY,
    StatusCode VARCHAR(30) NOT NULL,
    StatusName NVARCHAR(120) NOT NULL,
    SortOrder INT NOT NULL,
    IsFinal BIT NOT NULL CONSTRAINT DF_sales_OrderStatus_IsFinal DEFAULT (0),
    CONSTRAINT UQ_sales_OrderStatus_Code UNIQUE (StatusCode),
    CONSTRAINT UQ_sales_OrderStatus_Name UNIQUE (StatusName)
);
GO

CREATE TABLE sales.PaymentMethod
(
    PaymentMethodId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_PaymentMethod PRIMARY KEY,
    MethodCode VARCHAR(30) NOT NULL,
    MethodName NVARCHAR(120) NOT NULL,
    Description NVARCHAR(240) NULL,
    CONSTRAINT UQ_sales_PaymentMethod_Code UNIQUE (MethodCode),
    CONSTRAINT UQ_sales_PaymentMethod_Name UNIQUE (MethodName)
);
GO

CREATE TABLE sales.PaymentStatus
(
    PaymentStatusId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_PaymentStatus PRIMARY KEY,
    StatusCode VARCHAR(30) NOT NULL,
    StatusName NVARCHAR(120) NOT NULL,
    IsSuccessful BIT NOT NULL CONSTRAINT DF_sales_PaymentStatus_IsSuccessful DEFAULT (0),
    CONSTRAINT UQ_sales_PaymentStatus_Code UNIQUE (StatusCode),
    CONSTRAINT UQ_sales_PaymentStatus_Name UNIQUE (StatusName)
);
GO

CREATE TABLE sales.ShipmentCarrier
(
    ShipmentCarrierId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_ShipmentCarrier PRIMARY KEY,
    CarrierCode VARCHAR(20) NOT NULL,
    CarrierName NVARCHAR(120) NOT NULL,
    ServiceLevel NVARCHAR(80) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_sales_ShipmentCarrier_IsActive DEFAULT (1),
    CONSTRAINT UQ_sales_ShipmentCarrier_Code UNIQUE (CarrierCode),
    CONSTRAINT UQ_sales_ShipmentCarrier_Name UNIQUE (CarrierName)
);
GO

CREATE TABLE sales.ShipmentStatus
(
    ShipmentStatusId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_ShipmentStatus PRIMARY KEY,
    StatusCode VARCHAR(30) NOT NULL,
    StatusName NVARCHAR(120) NOT NULL,
    SortOrder INT NOT NULL,
    IsFinal BIT NOT NULL CONSTRAINT DF_sales_ShipmentStatus_IsFinal DEFAULT (0),
    CONSTRAINT UQ_sales_ShipmentStatus_Code UNIQUE (StatusCode),
    CONSTRAINT UQ_sales_ShipmentStatus_Name UNIQUE (StatusName)
);
GO

CREATE TABLE sales.ReturnReason
(
    ReturnReasonId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_ReturnReason PRIMARY KEY,
    ReasonCode VARCHAR(30) NOT NULL,
    ReasonName NVARCHAR(120) NOT NULL,
    IsCustomerFault BIT NOT NULL CONSTRAINT DF_sales_ReturnReason_IsCustomerFault DEFAULT (0),
    CONSTRAINT UQ_sales_ReturnReason_Code UNIQUE (ReasonCode),
    CONSTRAINT UQ_sales_ReturnReason_Name UNIQUE (ReasonName)
);
GO

CREATE TABLE sales.ReturnStatus
(
    ReturnStatusId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_ReturnStatus PRIMARY KEY,
    StatusCode VARCHAR(30) NOT NULL,
    StatusName NVARCHAR(120) NOT NULL,
    IsFinal BIT NOT NULL CONSTRAINT DF_sales_ReturnStatus_IsFinal DEFAULT (0),
    CONSTRAINT UQ_sales_ReturnStatus_Code UNIQUE (StatusCode),
    CONSTRAINT UQ_sales_ReturnStatus_Name UNIQUE (StatusName)
);
GO

CREATE TABLE sales.InventoryMovementType
(
    InventoryMovementTypeId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_InventoryMovementType PRIMARY KEY,
    MovementCode VARCHAR(30) NOT NULL,
    MovementName NVARCHAR(120) NOT NULL,
    Direction CHAR(1) NOT NULL,
    CONSTRAINT UQ_sales_InventoryMovementType_Code UNIQUE (MovementCode),
    CONSTRAINT UQ_sales_InventoryMovementType_Name UNIQUE (MovementName),
    CONSTRAINT CK_sales_InventoryMovementType_Direction CHECK (Direction IN ('I', 'O'))
);
GO

CREATE TABLE sales.SalesOrder
(
    OrderId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_SalesOrder PRIMARY KEY,
    OrderNumber VARCHAR(30) NOT NULL,
    CustomerId INT NOT NULL,
    BillingAddressId INT NOT NULL,
    ShippingAddressId INT NOT NULL,
    SalesChannelId INT NOT NULL,
    SalesRepId INT NULL,
    OrderStatusId INT NOT NULL,
    OrderDate DATETIME2(0) NOT NULL,
    RequiredDate DATE NULL,
    ApprovedAt DATETIME2(0) NULL,
    CurrencyCode CHAR(3) NOT NULL CONSTRAINT DF_sales_SalesOrder_CurrencyCode DEFAULT ('BRL'),
    Subtotal DECIMAL(18,2) NOT NULL CONSTRAINT DF_sales_SalesOrder_Subtotal DEFAULT (0),
    DiscountAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_sales_SalesOrder_DiscountAmount DEFAULT (0),
    ShippingAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_sales_SalesOrder_ShippingAmount DEFAULT (0),
    TaxAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_sales_SalesOrder_TaxAmount DEFAULT (0),
    TotalAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_sales_SalesOrder_TotalAmount DEFAULT (0),
    Notes NVARCHAR(300) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_SalesOrder_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_SalesOrder_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_sales_SalesOrder_Customer FOREIGN KEY (CustomerId) REFERENCES sales.Customer(CustomerId),
    CONSTRAINT FK_sales_SalesOrder_BillingAddress FOREIGN KEY (BillingAddressId) REFERENCES sales.CustomerAddress(CustomerAddressId),
    CONSTRAINT FK_sales_SalesOrder_ShippingAddress FOREIGN KEY (ShippingAddressId) REFERENCES sales.CustomerAddress(CustomerAddressId),
    CONSTRAINT FK_sales_SalesOrder_SalesChannel FOREIGN KEY (SalesChannelId) REFERENCES sales.SalesChannel(SalesChannelId),
    CONSTRAINT FK_sales_SalesOrder_SalesRep FOREIGN KEY (SalesRepId) REFERENCES sales.SalesRep(SalesRepId),
    CONSTRAINT FK_sales_SalesOrder_OrderStatus FOREIGN KEY (OrderStatusId) REFERENCES sales.OrderStatus(OrderStatusId),
    CONSTRAINT UQ_sales_SalesOrder_OrderNumber UNIQUE (OrderNumber),
    CONSTRAINT CK_sales_SalesOrder_Amounts CHECK
    (
        Subtotal >= 0
        AND DiscountAmount >= 0
        AND ShippingAmount >= 0
        AND TaxAmount >= 0
        AND TotalAmount >= 0
    )
);
GO

CREATE TABLE sales.SalesOrderItem
(
    OrderItemId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_SalesOrderItem PRIMARY KEY,
    OrderId INT NOT NULL,
    LineNumber INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitCost DECIMAL(18,2) NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    DiscountAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_sales_SalesOrderItem_DiscountAmount DEFAULT (0),
    LineTotal DECIMAL(18,2) NOT NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_SalesOrderItem_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_SalesOrderItem_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_sales_SalesOrderItem_Order FOREIGN KEY (OrderId) REFERENCES sales.SalesOrder(OrderId),
    CONSTRAINT FK_sales_SalesOrderItem_Product FOREIGN KEY (ProductId) REFERENCES sales.Product(ProductId),
    CONSTRAINT UQ_sales_SalesOrderItem_Line UNIQUE (OrderId, LineNumber),
    CONSTRAINT CK_sales_SalesOrderItem_Values CHECK
    (
        Quantity > 0
        AND UnitCost >= 0
        AND UnitPrice >= 0
        AND DiscountAmount >= 0
        AND LineTotal >= 0
    )
);
GO

CREATE TABLE sales.Payment
(
    PaymentId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_Payment PRIMARY KEY,
    OrderId INT NOT NULL,
    PaymentMethodId INT NOT NULL,
    PaymentStatusId INT NOT NULL,
    PaymentDate DATETIME2(0) NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    InstallmentCount TINYINT NOT NULL CONSTRAINT DF_sales_Payment_InstallmentCount DEFAULT (1),
    PaymentReference VARCHAR(40) NOT NULL,
    Notes NVARCHAR(240) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Payment_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Payment_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_sales_Payment_Order FOREIGN KEY (OrderId) REFERENCES sales.SalesOrder(OrderId),
    CONSTRAINT FK_sales_Payment_Method FOREIGN KEY (PaymentMethodId) REFERENCES sales.PaymentMethod(PaymentMethodId),
    CONSTRAINT FK_sales_Payment_Status FOREIGN KEY (PaymentStatusId) REFERENCES sales.PaymentStatus(PaymentStatusId),
    CONSTRAINT UQ_sales_Payment_Reference UNIQUE (PaymentReference),
    CONSTRAINT CK_sales_Payment_Values CHECK (Amount >= 0 AND InstallmentCount >= 1)
);
GO

CREATE TABLE sales.Shipment
(
    ShipmentId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_Shipment PRIMARY KEY,
    OrderId INT NOT NULL,
    ShipmentNumber VARCHAR(30) NOT NULL,
    ShipmentCarrierId INT NOT NULL,
    ShipmentStatusId INT NOT NULL,
    TrackingCode VARCHAR(40) NULL,
    ShippedAt DATETIME2(0) NOT NULL,
    EstimatedDeliveryDate DATE NULL,
    DeliveredAt DATETIME2(0) NULL,
    FreightAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_sales_Shipment_FreightAmount DEFAULT (0),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Shipment_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_Shipment_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_sales_Shipment_Order FOREIGN KEY (OrderId) REFERENCES sales.SalesOrder(OrderId),
    CONSTRAINT FK_sales_Shipment_Carrier FOREIGN KEY (ShipmentCarrierId) REFERENCES sales.ShipmentCarrier(ShipmentCarrierId),
    CONSTRAINT FK_sales_Shipment_Status FOREIGN KEY (ShipmentStatusId) REFERENCES sales.ShipmentStatus(ShipmentStatusId),
    CONSTRAINT UQ_sales_Shipment_Order UNIQUE (OrderId),
    CONSTRAINT UQ_sales_Shipment_Number UNIQUE (ShipmentNumber),
    CONSTRAINT CK_sales_Shipment_Freight CHECK (FreightAmount >= 0)
);
GO

CREATE UNIQUE INDEX UX_sales_Shipment_TrackingCode
    ON sales.Shipment(TrackingCode)
    WHERE TrackingCode IS NOT NULL;
GO

CREATE TABLE sales.ReturnHeader
(
    ReturnId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_ReturnHeader PRIMARY KEY,
    ReturnNumber VARCHAR(30) NOT NULL,
    OrderId INT NOT NULL,
    CustomerId INT NOT NULL,
    ReturnReasonId INT NOT NULL,
    ReturnStatusId INT NOT NULL,
    RequestedAt DATETIME2(0) NOT NULL,
    ApprovedAt DATETIME2(0) NULL,
    CompletedAt DATETIME2(0) NULL,
    RefundAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_sales_ReturnHeader_RefundAmount DEFAULT (0),
    Notes NVARCHAR(300) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_ReturnHeader_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_ReturnHeader_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_sales_ReturnHeader_Order FOREIGN KEY (OrderId) REFERENCES sales.SalesOrder(OrderId),
    CONSTRAINT FK_sales_ReturnHeader_Customer FOREIGN KEY (CustomerId) REFERENCES sales.Customer(CustomerId),
    CONSTRAINT FK_sales_ReturnHeader_Reason FOREIGN KEY (ReturnReasonId) REFERENCES sales.ReturnReason(ReturnReasonId),
    CONSTRAINT FK_sales_ReturnHeader_Status FOREIGN KEY (ReturnStatusId) REFERENCES sales.ReturnStatus(ReturnStatusId),
    CONSTRAINT UQ_sales_ReturnHeader_Number UNIQUE (ReturnNumber),
    CONSTRAINT CK_sales_ReturnHeader_RefundAmount CHECK (RefundAmount >= 0)
);
GO

CREATE TABLE sales.ReturnItem
(
    ReturnItemId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_ReturnItem PRIMARY KEY,
    ReturnId INT NOT NULL,
    OrderItemId INT NOT NULL,
    QuantityReturned INT NOT NULL,
    UnitRefundAmount DECIMAL(18,2) NOT NULL,
    LineRefundAmount DECIMAL(18,2) NOT NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_ReturnItem_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_ReturnItem_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_sales_ReturnItem_ReturnHeader FOREIGN KEY (ReturnId) REFERENCES sales.ReturnHeader(ReturnId),
    CONSTRAINT FK_sales_ReturnItem_OrderItem FOREIGN KEY (OrderItemId) REFERENCES sales.SalesOrderItem(OrderItemId),
    CONSTRAINT UQ_sales_ReturnItem_OrderItem UNIQUE (ReturnId, OrderItemId),
    CONSTRAINT CK_sales_ReturnItem_Values CHECK
    (
        QuantityReturned > 0
        AND UnitRefundAmount >= 0
        AND LineRefundAmount >= 0
    )
);
GO

CREATE TABLE sales.InventoryMovement
(
    InventoryMovementId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_InventoryMovement PRIMARY KEY,
    ProductId INT NOT NULL,
    InventoryMovementTypeId INT NOT NULL,
    SupplierId INT NULL,
    OrderItemId INT NULL,
    ReturnItemId INT NULL,
    MovementDate DATETIME2(0) NOT NULL,
    QuantityChange INT NOT NULL,
    UnitCost DECIMAL(18,2) NULL,
    ReferenceNote NVARCHAR(250) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_sales_InventoryMovement_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_sales_InventoryMovement_Product FOREIGN KEY (ProductId) REFERENCES sales.Product(ProductId),
    CONSTRAINT FK_sales_InventoryMovement_Type FOREIGN KEY (InventoryMovementTypeId) REFERENCES sales.InventoryMovementType(InventoryMovementTypeId),
    CONSTRAINT FK_sales_InventoryMovement_Supplier FOREIGN KEY (SupplierId) REFERENCES sales.Supplier(SupplierId),
    CONSTRAINT FK_sales_InventoryMovement_OrderItem FOREIGN KEY (OrderItemId) REFERENCES sales.SalesOrderItem(OrderItemId),
    CONSTRAINT FK_sales_InventoryMovement_ReturnItem FOREIGN KEY (ReturnItemId) REFERENCES sales.ReturnItem(ReturnItemId),
    CONSTRAINT CK_sales_InventoryMovement_Quantity CHECK (QuantityChange <> 0)
);
GO

CREATE INDEX IX_sales_Subcategory_CategoryId
    ON sales.Subcategory(CategoryId);
GO

CREATE INDEX IX_sales_Product_SubcategoryId
    ON sales.Product(SubcategoryId, BrandId, SupplierId, IsActive);
GO

CREATE INDEX IX_sales_CustomerAddress_CustomerId
    ON sales.CustomerAddress(CustomerId, AddressType, IsPrimary);
GO

CREATE INDEX IX_sales_SalesOrder_OrderDate
    ON sales.SalesOrder(OrderDate, CustomerId, OrderStatusId, SalesChannelId);
GO

CREATE INDEX IX_sales_SalesOrderItem_OrderId
    ON sales.SalesOrderItem(OrderId, ProductId);
GO

CREATE INDEX IX_sales_SalesOrderItem_ProductId
    ON sales.SalesOrderItem(ProductId, OrderId);
GO

CREATE INDEX IX_sales_Payment_OrderId
    ON sales.Payment(OrderId, PaymentStatusId, PaymentDate);
GO

CREATE INDEX IX_sales_Shipment_ShippedAt
    ON sales.Shipment(ShippedAt, ShipmentStatusId, ShipmentCarrierId);
GO

CREATE INDEX IX_sales_ReturnHeader_RequestedAt
    ON sales.ReturnHeader(RequestedAt, ReturnStatusId, OrderId);
GO

CREATE INDEX IX_sales_InventoryMovement_ProductId
    ON sales.InventoryMovement(ProductId, MovementDate, InventoryMovementTypeId);
GO
