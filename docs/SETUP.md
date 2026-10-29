# Environment setup

## Requirements

- Microsoft Excel with Power Query to inspect the source and cleaned workbooks
- SQL Server 2017+ and SSMS (SQL uses `TRIM`, `TRY_CAST`, window functions and `CREATE OR ALTER VIEW`)
- Power BI Desktop for the companion report file
- Python 3.11+ to run static repository checks (standard library only)

## Load

1. Obtain Excel and Power BI binary assets described in [ASSET_MANIFEST.md](ASSET_MANIFEST.md). These are not currently stored in GitHub.
2. Create database `UrbanCart` in SQL Server. Do not run this workflow against an existing production database.
3. Import the five cleaned sheets as staging tables with names and columns: `dbo.Customers_Clean`, `dbo.Products_Clean`, `dbo.Orders_Clean`, `dbo.Order_Items_Clean` and `dbo.Return_Clean`.
4. Check row counts against [data/README.md](../data/README.md) and inspect SQL pre-load checks before running any modifying statements.
5. Execute `sql/01_schema_and_load.sql` in order; do not rerun the DDL without clearing your test database.
6. Run `sql/02_analysis_and_views.sql` and optionally `sql/03_advanced_analytics.sql`.
7. In Power BI Desktop open the original `.pbix`, edit the SQL Server connection and refresh. Check slicers, report totals, relationships and error notifications.

## Validation

```bash
python scripts/validate_repository.py
```

The Python check validates committed source files and obvious SQL safety markers. It does **not** connect to SQL Server or Power BI.
