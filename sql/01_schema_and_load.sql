/* UrbanCart | SQL Server schema and guarded staging load
   USE ONLY IN A NEW, EMPTY UrbanCart training database.
   Prerequisite: import the five cleaned Excel sheets as dbo.*_Clean staging tables.
   Review staging duplicates/anomalies before executing this file.
   Executes one time; re-running CREATE TABLE requires a clean database. */
USE UrbanCart;
GO

-- Review source counts before loading.
SELECT 'Customers_Clean' AS source_table, COUNT(*) AS records FROM dbo.Customers_Clean
UNION ALL SELECT 'Products_Clean', COUNT(*) FROM dbo.Products_Clean
UNION ALL SELECT 'Orders_Clean', COUNT(*) FROM dbo.Orders_Clean
UNION ALL SELECT 'Order_Items_Clean', COUNT(*) FROM dbo.Order_Items_Clean
UNION ALL SELECT 'Return_Clean', COUNT(*) FROM dbo.Return_Clean;
GO

SELECT OrderItemID, COUNT(*) AS occurrences
FROM dbo.Order_Items_Clean
GROUP BY OrderItemID HAVING COUNT(*) > 1;
GO

/* Stop immediately if parent-key duplicates exist.
   The duplicate OrderItemIDs are handled in staging only. */
IF EXISTS (SELECT 1 FROM dbo.Customers_Clean GROUP BY customerid HAVING COUNT(*) > 1)
 OR EXISTS (SELECT 1 FROM dbo.Products_Clean GROUP BY ProductID HAVING COUNT(*) > 1)
 OR EXISTS (SELECT 1 FROM dbo.Orders_Clean GROUP BY OrderID HAVING COUNT(*) > 1)
 OR EXISTS (SELECT 1 FROM dbo.Return_Clean GROUP BY ReturnID HAVING COUNT(*) > 1)
    THROW 51010, 'Unexpected duplicate parent ID detected; inspect staging first.', 1;
GO

-- Reject unmatched foreign keys instead of hiding conversion/loading problems.
IF EXISTS (
    SELECT 1 FROM dbo.Orders_Clean o
    LEFT JOIN dbo.Customers_Clean c ON c.customerid = o.CustomerID
    WHERE c.customerid IS NULL
) THROW 51011, 'Orders contain unknown CustomerID.', 1;
IF EXISTS (
    SELECT 1 FROM dbo.Order_Items_Clean x
    LEFT JOIN dbo.Orders_Clean o ON o.OrderID = x.OrderID
    WHERE o.OrderID IS NULL
) THROW 51012, 'Order items contain unknown OrderID.', 1;
IF EXISTS (
    SELECT 1 FROM dbo.Order_Items_Clean x
    LEFT JOIN dbo.Products_Clean p ON p.ProductID = x.ProductID
    WHERE p.ProductID IS NULL
) THROW 51013, 'Order items contain unknown ProductID.', 1;
IF EXISTS (
    SELECT 1 FROM dbo.Return_Clean r
    LEFT JOIN dbo.Orders_Clean o ON o.OrderID = r.OrderID
    WHERE o.OrderID IS NULL
) THROW 51014, 'Returns contain unknown OrderID.', 1;
IF EXISTS (
    SELECT 1 FROM dbo.Return_Clean r
    LEFT JOIN dbo.Products_Clean p ON p.ProductID = r.ProductID
    WHERE p.ProductID IS NULL
) THROW 51015, 'Returns contain unknown ProductID.', 1;
GO

/* Preserve source files. Apply deterministic de-duplication to imported staging only.
   Inspect duplicates before running; if conflicting duplicates exist, obtain a business rule. */
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    ;WITH Ranked AS (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY OrderItemID
                   ORDER BY OrderID, ProductID, Quantity, UnitPriceAtSale, [Discount ], LineTotal
               ) AS rn
        FROM dbo.Order_Items_Clean
    )
    DELETE FROM Ranked WHERE rn > 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

IF EXISTS (SELECT 1 FROM dbo.Order_Items_Clean GROUP BY OrderItemID HAVING COUNT(*) > 1)
    THROW 51016, 'OrderItemID duplicate still present.', 1;
GO

CREATE TABLE dbo.Customers (
    CustomerID NVARCHAR(50) NOT NULL PRIMARY KEY,
    CustomerName NVARCHAR(255) NULL, Email NVARCHAR(255) NULL,
    Phone NVARCHAR(50) NULL, Gender NVARCHAR(20) NULL,
    DateOfBirth DATE NULL, SignupDate DATE NULL,
    City NVARCHAR(100) NULL, State NVARCHAR(100) NULL, Country NVARCHAR(100) NULL,
    CustomerSegment NVARCHAR(100) NULL
);
CREATE TABLE dbo.Products (
    ProductID NVARCHAR(50) NOT NULL PRIMARY KEY,
    ProductName NVARCHAR(255) NULL, Category NVARCHAR(100) NULL,
    SubCategory NVARCHAR(100) NULL, Brand NVARCHAR(100) NULL,
    UnitPrice DECIMAL(12,2) NULL, CostPrice DECIMAL(12,2) NULL,
    StockQuantity INT NULL
);
CREATE TABLE dbo.Orders (
    OrderID NVARCHAR(50) NOT NULL PRIMARY KEY,
    CustomerID NVARCHAR(50) NOT NULL REFERENCES dbo.Customers(CustomerID),
    OrderDate DATE NULL, ShipDate DATE NULL, DeliveryDate DATE NULL,
    DataValidation NVARCHAR(255) NULL,
    Channel NVARCHAR(100) NULL, PaymentMode NVARCHAR(100) NULL,
    Region NVARCHAR(100) NULL, State NVARCHAR(100) NULL,
    OrderStatus NVARCHAR(100) NULL, CalculatedOrderStatus NVARCHAR(255) NULL,
    ShippingCost DECIMAL(12,2) NULL
);
CREATE TABLE dbo.Order_Items (
    OrderItemID NVARCHAR(50) NOT NULL PRIMARY KEY,
    OrderID NVARCHAR(50) NOT NULL REFERENCES dbo.Orders(OrderID),
    ProductID NVARCHAR(50) NOT NULL REFERENCES dbo.Products(ProductID),
    Quantity INT NULL, UnitPriceAtSale DECIMAL(12,2) NULL,
    Discount DECIMAL(9,4) NULL, LineTotal DECIMAL(14,2) NULL
);
CREATE TABLE dbo.Returns (
    ReturnID NVARCHAR(50) NOT NULL PRIMARY KEY,
    OrderID NVARCHAR(50) NOT NULL REFERENCES dbo.Orders(OrderID),
    ProductID NVARCHAR(50) NOT NULL REFERENCES dbo.Products(ProductID),
    ReturnDateClean DATETIME NULL, ReturnReason NVARCHAR(255) NULL,
    RefundAmount DECIMAL(12,2) NULL
);
CREATE INDEX IX_Orders_CustomerID ON dbo.Orders(CustomerID);
CREATE INDEX IX_Orders_OrderDate ON dbo.Orders(OrderDate);
CREATE INDEX IX_OrderItems_OrderID ON dbo.Order_Items(OrderID);
CREATE INDEX IX_OrderItems_ProductID ON dbo.Order_Items(ProductID);
CREATE INDEX IX_Returns_OrderID ON dbo.Returns(OrderID);
CREATE INDEX IX_Returns_ProductID ON dbo.Returns(ProductID);
GO

SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM dbo.Customers) OR EXISTS (SELECT 1 FROM dbo.Products)
       OR EXISTS (SELECT 1 FROM dbo.Orders) OR EXISTS (SELECT 1 FROM dbo.Order_Items)
       OR EXISTS (SELECT 1 FROM dbo.Returns)
       THROW 51017, 'Target tables are not empty; aborting.', 1;

    INSERT INTO dbo.Customers
      (CustomerID,CustomerName,Email,Phone,Gender,DateOfBirth,SignupDate,City,State,Country,CustomerSegment)
    SELECT customerid,customername,email,phone,gender,dateofbirth,signupdate,city,state,country,customersegment
    FROM dbo.Customers_Clean;

    INSERT INTO dbo.Products
      (ProductID,ProductName,Category,SubCategory,Brand,UnitPrice,CostPrice,StockQuantity)
    SELECT ProductID,ProductName,Category,SubCategory,Brand,
      TRY_CAST(UnitPrice AS DECIMAL(12,2)),TRY_CAST(CostPrice AS DECIMAL(12,2)),
      TRY_CAST(StockQuantity AS INT) FROM dbo.Products_Clean;

    INSERT INTO dbo.Orders
      (OrderID,CustomerID,OrderDate,ShipDate,DeliveryDate,DataValidation,Channel,PaymentMode,Region,State,OrderStatus,CalculatedOrderStatus,ShippingCost)
    SELECT OrderID,CustomerID,OrderDate,ShipDate,DeliveryDate,DataValidation,
      Channel,PaymentMode,Region,State,OrderStatus,CalculatedOrderStatus,
      TRY_CAST(ShippingCost AS DECIMAL(12,2)) FROM dbo.Orders_Clean;

    INSERT INTO dbo.Order_Items
      (OrderItemID,OrderID,ProductID,Quantity,UnitPriceAtSale,Discount,LineTotal)
    SELECT OrderItemID,OrderID,ProductID,TRY_CAST(Quantity AS INT),
      TRY_CAST(UnitPriceAtSale AS DECIMAL(12,2)),
      TRY_CAST([Discount ] AS DECIMAL(9,4)),
      TRY_CAST(LineTotal AS DECIMAL(14,2)) FROM dbo.Order_Items_Clean;

    INSERT INTO dbo.Returns
      (ReturnID,OrderID,ProductID,ReturnDateClean,ReturnReason,RefundAmount)
    SELECT ReturnID,OrderID,ProductID,ReturnDateClean,ReturnReason,
      TRY_CAST(RefundAmount AS DECIMAL(12,2)) FROM dbo.Return_Clean;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
-- Verify model counts and reconcile gross sales.
SELECT 'Customers' AS entity, COUNT(*) AS n FROM dbo.Customers
UNION ALL SELECT 'Products', COUNT(*) FROM dbo.Products
UNION ALL SELECT 'Orders', COUNT(*) FROM dbo.Orders
UNION ALL SELECT 'Order_Items', COUNT(*) FROM dbo.Order_Items
UNION ALL SELECT 'Returns', COUNT(*) FROM dbo.Returns;
SELECT SUM(LineTotal) AS gross_sales FROM dbo.Order_Items;
GO
