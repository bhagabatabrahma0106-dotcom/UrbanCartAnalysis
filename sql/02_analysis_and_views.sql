/* UrbanCart | reusable read-only reporting views
   Prerequisite: execute sql/01_schema_and_load.sql in a clean training database.
   Revenue includes anomalies; view calculations do not mutate source data. */
USE UrbanCart;
GO
CREATE OR ALTER VIEW dbo.vw_RevenueTrend AS
SELECT YEAR(o.OrderDate) AS SalesYear, MONTH(o.OrderDate) AS SalesMonth,
       COUNT(DISTINCT o.OrderID) AS Orders,
       SUM(i.LineTotal) AS Revenue
FROM dbo.Orders o JOIN dbo.Order_Items i ON i.OrderID=o.OrderID
GROUP BY YEAR(o.OrderDate),MONTH(o.OrderDate);
GO
CREATE OR ALTER VIEW dbo.vw_RegionalSalesPerformance AS
SELECT o.Region,o.State,COUNT(DISTINCT o.OrderID) AS OrderVolume,
       SUM(i.LineTotal) AS Revenue
FROM dbo.Orders o JOIN dbo.Order_Items i ON i.OrderID=o.OrderID
GROUP BY o.Region,o.State;
GO
CREATE OR ALTER VIEW dbo.vw_ProductPerformance AS
SELECT p.ProductID,p.ProductName,p.Category,p.SubCategory,
       SUM(i.Quantity) AS UnitsSold,SUM(i.LineTotal) AS Revenue
FROM dbo.Products p JOIN dbo.Order_Items i ON i.ProductID=p.ProductID
GROUP BY p.ProductID,p.ProductName,p.Category,p.SubCategory;
GO
CREATE OR ALTER VIEW dbo.vw_ChannelRevenue AS
SELECT TRIM(o.Channel) AS Channel,
       COUNT(DISTINCT o.OrderID) AS OrderVolume,SUM(i.LineTotal) AS Revenue
FROM dbo.Orders o JOIN dbo.Order_Items i ON i.OrderID=o.OrderID
GROUP BY TRIM(o.Channel);
GO
CREATE OR ALTER VIEW dbo.vw_PaymentModeRevenue AS
SELECT TRIM(o.PaymentMode) AS PaymentMode,
       COUNT(DISTINCT o.OrderID) AS OrderVolume,SUM(i.LineTotal) AS Revenue
FROM dbo.Orders o JOIN dbo.Order_Items i ON i.OrderID=o.OrderID
GROUP BY TRIM(o.PaymentMode);
GO
CREATE OR ALTER VIEW dbo.vw_CustomerSegmentPerformance AS
SELECT c.CustomerSegment,
       COUNT(DISTINCT o.OrderID) AS Orders,
       COUNT(DISTINCT o.CustomerID) AS OrderingCustomers,
       SUM(i.LineTotal) AS Revenue,
       CAST(SUM(i.LineTotal)/NULLIF(COUNT(DISTINCT o.OrderID),0) AS DECIMAL(18,2)) AS AOV,
       CAST(COUNT(DISTINCT o.OrderID)*1.0/NULLIF(COUNT(DISTINCT o.CustomerID),0) AS DECIMAL(18,2)) AS OrdersPerCustomer
FROM dbo.Customers c JOIN dbo.Orders o ON o.CustomerID=c.CustomerID
JOIN dbo.Order_Items i ON i.OrderID=o.OrderID
GROUP BY c.CustomerSegment;
GO
CREATE OR ALTER VIEW dbo.vw_ReturnAnalysis AS
SELECT p.Category,
       COUNT(DISTINCT r.OrderID) AS ReturnedOrders,
       COUNT(*) AS ReturnRecords,
       SUM(COALESCE(r.RefundAmount,0)) AS RefundAmount
FROM dbo.Returns r JOIN dbo.Products p ON p.ProductID=r.ProductID
GROUP BY p.Category;
GO
CREATE OR ALTER VIEW dbo.vw_RepeatCustomerRate AS
WITH CustomerOrders AS (
 SELECT o.CustomerID,COUNT(DISTINCT o.OrderID) AS OrderCount
 FROM dbo.Orders o GROUP BY o.CustomerID
)
SELECT COUNT(*) AS OrderingCustomers,
 SUM(CASE WHEN OrderCount>=2 THEN 1 ELSE 0 END) AS RepeatCustomers,
 CAST(100.0*SUM(CASE WHEN OrderCount>=2 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS DECIMAL(8,2)) AS RepeatRatePct
FROM CustomerOrders;
GO
CREATE OR ALTER VIEW dbo.vw_AverageDeliveryTime AS
SELECT o.Region,COUNT(*) AS ValidDeliveredOrders,
 CAST(AVG(CAST(DATEDIFF(DAY,o.ShipDate,o.DeliveryDate) AS FLOAT)) AS DECIMAL(12,2)) AS AvgDeliveryDays
FROM dbo.Orders o
WHERE o.ShipDate IS NOT NULL AND o.DeliveryDate IS NOT NULL
 AND o.OrderDate IS NOT NULL
 AND o.ShipDate>=o.OrderDate AND o.DeliveryDate>=o.ShipDate
GROUP BY o.Region;
GO
-- Read-only spot checks
SELECT TOP 12 * FROM dbo.vw_RevenueTrend ORDER BY SalesYear,SalesMonth;
SELECT TOP 10 * FROM dbo.vw_ProductPerformance ORDER BY Revenue DESC;
SELECT * FROM dbo.vw_RepeatCustomerRate;
GO
