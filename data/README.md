# Dataset and provenance

The project uses **synthetic retail data**; it is not a real customer's personal or business dataset. Its original Excel files are included in the companion `UrbanCartAnalysis_GitHub_Ready.zip` package, not currently committed here.

| Sheet | Raw rows | Cleaned rows | Expected SQL rows |
|---|---:|---:|---:|
| Customers / Customers_Clean | 3060 | 3000 | 3000 |
| Products / Products_Clean | 161 | 156 | 156 |
| Orders / Orders_Clean | 10000 | 10000 | 10000 |
| Order_Items / Order_Items_Clean | 20643 | 20643 | 20523 |
| Returns / Return_Clean | 793 | 793 | 793 |

Workbook names: `UrbanCart_Raw_Sales_Data.xlsx`, `UrbanCart_Cleaned_Sales_Data.xlsx`. Both include a `Data_Dictionary` worksheet. The cleaned workbook retains 120 duplicated OrderItemIDs; SQL staging removes those after inspection.

Do not commit real-world customer PII, secrets or proprietary data. Review before publishing any replacement dataset.
