# Data quality and audit policy

| Finding | Impact | Decision |
|---|---|---|
| 120 duplicate order-line IDs | Primary key collision and inflated revenue | Inspect duplicate rows; deduplicate imported SQL staging, keeping original Excel intact |
| 112 lines with quantity 500 | Approximately 61% of gross sales | Preserve and flag as high-quantity sensitivity |
| 213 zero-quantity lines | Could indicate cancellations, promotions or erroneous inputs | Preserve and flag |
| 209 invalid delivery-before-order dates | Biased delivery KPIs | Exclude physically invalid pairs from lead-time metrics |
| Mixed channel labels and spacing | Fragmented grouping | Normalize in reporting queries with `TRIM` |
| Manual Excel cleaning steps | Limits deterministic reproduction | Document procedure; prioritize reproducible Power Query transformation |

Do not automatically delete atypical records merely to produce attractive KPI totals. Outlier-excluded comparisons should be named as scenarios.

Validation status: offline package checks were performed for the companion archive. SQL execution and Power BI Desktop refresh have not been confirmed in this environment.
