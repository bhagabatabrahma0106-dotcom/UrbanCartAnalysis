# Architecture

## Flow

1. Raw synthetic retail exports are retained in Excel workbooks.
2. Cleaned sheets become SQL Server `*_Clean` staging tables.
3. SQL validation checks key uniqueness and references; duplicate order lines are reviewed and removed only from staging.
4. The relational model stores Customers, Products, Orders, Order_Items and Returns.
5. Nine reporting views support recurring analysis.
6. Power BI uses the five model tables for the delivered two-page report.

## Cardinality

- Customers (1) → Orders (many)
- Orders (1) → Order_Items (many)
- Products (1) → Order_Items (many)
- Orders (1) → Returns (zero or many in theory; sample contains at most one per order)
- Products (1) → Returns (many)

Revenue must be aggregated at order-line grain; order volume uses distinct order IDs to avoid double counting.

## Reproducibility boundary

Excel source workbooks, a Power BI report and supporting documents are now committed. SQL uses local SSMS-imported staging tables. The uploaded Power BI version has not been Desktop-refresh validated. This source repository is not a deployed cloud service.
