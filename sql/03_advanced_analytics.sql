/* UrbanCart | advanced analytics (read-only). Requires reporting views. */
USE UrbanCart;
GO
WITH Monthly AS (
 SELECT DATEFROMPARTS(SalesYear,SalesMonth,1) AS MonthStart,Revenue
 FROM dbo.vw_RevenueTrend
), Trends AS (
 SELECT MonthStart,Revenue,
        SUM(Revenue) OVER(ORDER BY MonthStart ROWS UNBOUNDED PRECEDING) AS RunningRevenue,
        LAG(Revenue) OVER(ORDER BY MonthStart) AS PreviousMonthRevenue,
        LAG(Revenue,12) OVER(ORDER BY MonthStart) AS PreviousYearRevenue
 FROM Monthly
)
SELECT MonthStart,Revenue,RunningRevenue,
 CAST(100.0*(Revenue-PreviousMonthRevenue)/NULLIF(PreviousMonthRevenue,0) AS DECIMAL(12,2)) AS MoMPct,
 CAST(100.0*(Revenue-PreviousYearRevenue)/NULLIF(PreviousYearRevenue,0) AS DECIMAL(12,2)) AS YoYPct
FROM Trends ORDER BY MonthStart;
GO
SELECT ProductID,ProductName,Category,Revenue,
       DENSE_RANK() OVER(PARTITION BY Category ORDER BY Revenue DESC) AS CategoryRevenueRank
FROM dbo.vw_ProductPerformance ORDER BY Category,CategoryRevenueRank;
GO
SELECT
 COUNT(*) AS TotalLines,
 SUM(CASE WHEN Quantity=500 THEN 1 ELSE 0 END) AS Qty500Lines,
 SUM(CASE WHEN Quantity=0 THEN 1 ELSE 0 END) AS ZeroQtyLines,
 SUM(LineTotal) AS GrossSales,
 SUM(CASE WHEN Quantity=500 THEN LineTotal ELSE 0 END) AS GrossSalesQty500
FROM dbo.Order_Items;
GO
