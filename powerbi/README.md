# Power BI report handover

The user-uploaded [UrbanCart_Dashboard.pbix](UrbanCart_Dashboard.pbix) is now committed (1,662,323 bytes). It differs from the earlier packaged 4,813,407-byte PBIX. The uploaded version was preserved byte-for-byte; it still needs to be opened, refreshed and reviewed in Power BI Desktop before confirming its visuals and model.

Report structure: 2 pages, `Home` and `Performance`; KPI cards, revenue trend and product/channel/region/segment visuals. Measures from the supplied report are:

```dax
Total Revenue = SUM(Order_Items[LineTotal])
Total Orders = DISTINCTCOUNT(Orders[OrderID])
Total Customers = DISTINCTCOUNT(Customers[CustomerID])
Average Order Value = DIVIDE([Total Revenue], [Total Orders], 0)
Return Rate =
DIVIDE(
    CALCULATE(
        DISTINCTCOUNT(Orders[OrderID]),
        TREATAS(VALUES(Returns[OrderID]), Orders[OrderID])
    ),
    DISTINCTCOUNT(Orders[OrderID]),
    0
)
```

The original report uses a local SQL Server data-source connection. Change the connection in Power BI Desktop, refresh and compare counts to [METRICS.md](../docs/METRICS.md). The corrected report metadata was inspected offline; a full Desktop opening/refresh test was **not** performed. Avoid presenting the reference HTML as a live Power BI app.
