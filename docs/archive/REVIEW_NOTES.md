# Review Notes

Documentation review of the UrbanCart project before publishing to GitHub. Findings are based on inspecting the delivered files themselves (both workbooks, both SQL scripts, the `.pbix` model and report definition), not on the planning documents.

## 1. What was changed

| Item | Change |
|---|---|
| `README.md` | New. Replaces the original `README.txt`, which described a learner starter pack ("clean this in Excel", "rebuild it in Power BI") rather than the finished project |
| `sql/01_schema_and_load.sql` (was `UrbanCartDataModelling.sql`) | Rewrote the header (purpose, inputs/outputs, run order, design notes); documented the duplicate-removal block; **commented out** one destructive statement (see 2a) |
| `sql/02_analysis_and_views.sql` (was `UrbanCartAnalysis.sql`) | Replaced the header (it was a pasted copy of BRD requirements) with a proper one; organized into Part A (queries) and Part B (views); added the business question, expected output and caveats to each query; added statement terminators; changed `CREATE VIEW vw_RevenueTrend` to `CREATE OR ALTER VIEW` so the script can be re-run. **No query logic was altered** |
| Folder layout | `Raw_Files/`, `Analyze_Files/` → `data/`, `sql/`, `powerbi/`, `docs/`. `UrbanCartDashboardPresntation.pbix` → `UrbanCart_Dashboard.pbix` (file renamed only; contents untouched) |
| Removed | `~$banCart_Business_Requirement_Document.docx` (Word lock file) and `README.txt` (superseded) |
| Unchanged | Both workbooks, the `.pbix`, the BRD, the walkthrough deck and the HTML dashboard reference |

## 2. Decisions that touch code, for your approval

a. **Destructive DELETE commented out.** `DELETE FROM Order_Items_Clean WHERE EXISTS (<duplicate subquery>)` is not correlated to the outer row, so it deletes every row in the table whenever one duplicate exists. Your own note beside it said as much. It is preserved inside a comment block marked *DO NOT RUN*; the `ROW_NUMBER()` approach that follows it is the working method.

b. **Duplicate-removal block is a dry run as saved.** It ends with `ROLLBACK TRANSACTION; COMMIT TRANSACTION;`; the `COMMIT` raises error 3902 because the transaction is already closed. Left as written, with a comment explaining how to apply it. The loaded data (20,523 order lines) shows the duplicates were removed in your own run.

c. **`CREATE OR ALTER VIEW`** for `vw_RevenueTrend` (the other eight already used it).

## 3. Corrections to statements in the original package

| Original statement (README.txt / BRD / deck) | What the delivered project shows |
|---|---|
| SQL on "PostgreSQL, MySQL, or SQLite" | SQL Server / T-SQL (`TOP`, `DATEPART`, `TRIM`, `CREATE OR ALTER`, SSMS import) |
| "~34,600 rows"; Customers ~3,060 etc. | Raw rows total 34,657. Cleaned data holds 3,000 customers and 156 products; the Order_Items table holds 20,523 rows after SQL de-duplication |
| Dashboard with "at least 4 report pages" | 2 pages (*Home*, *Performance*) |
| Star schema with a Date dimension | Fact/dimension relationships exist; no Date table (auto date/time only) |
| DAX: Total Revenue, Orders, AOV, Return Rate, YoY/MoM, Top Category Share | 5 measures: Total Revenue, Total Orders, Total Customers, Average Order Value, Return Rate. No YoY/MoM or Top Category Share |
| Window functions in ≥2 analyses | None in the analysis scripts (`ROW_NUMBER()` is used only for de-duplication) |
| Revenue by Region, **State, and City** | Region and State only; `City` is not on Orders |
| "Dashboard reference ... Power BI-style" | Accurate: the HTML is a design reference; the working report is the `.pbix` |

The BRD and deck are left as the original planning documents (BRD status: "Draft — for self-review before build"). The traceability table below records what was actually delivered.

## 4. Requirement traceability (BRD → delivered)

Status: **Met**, **Partial**, **Open**.

| ID | Requirement (short) | Status | Evidence / note |
|---|---|---|---|
| FR1 | Remove duplicates in Customers and Order_Items | Partial | Customers: 60 removed in Excel. Order_Items: 120 removed in SQL, not Excel, and not in the cleaning log |
| FR2 | Dates in ISO format | Met | Power Query; stored as `DATE` in SQL |
| FR3 | Normalize text (Gender, Channel, PaymentMode, Category) | Partial | Gender, Category done. Channel trimmed in SQL; PaymentMode still has whitespace variants (12 distinct vs 6) |
| FR4 | One null marker | Met | `N/A` (Customers); blank return reasons → `N/A` in Power Query |
| FR5 | City typos | Met | Logged (1 fix) |
| FR6 | UnitPrice numeric | Met | |
| FR7 | Discount one format | Met | Percentage points, 0–25 |
| FR8 | Recompute LineTotal | Met | Formula holds on 100% of rows |
| FR9 | Flag quantity outliers | **Open** | 112 lines with quantity 500 and 213 with quantity 0 remain, unflagged |
| FR10 | Negative stock / cost | Met | No negative values in cleaned Products (negative costs fixed per the log) |
| FR11 | Complete cleaning log | Partial | Covers Customers, Products and `Orders.OrderDate`; Orders (other columns), Order_Items and Returns not logged. Sheet is still titled "(template)" |
| FR12 | Export cleaned tables | Met | `UrbanCart_Cleaned_Sales_Data.xlsx` |
| FR13 | Relational schema with PK/FK | Met | 5 tables, 6 indexes |
| FR14 | Business queries | Mostly met | All 8 topics answered; no city-level view; return rate by *product* not produced |
| FR15 | Window functions in ≥2 analyses | **Open** | Base set provided (query A10) |
| FR16 | Reusable views | Met | 9 views |
| FR17 | Document each query | Met | Added in this review |
| FR18 | Star-schema model | Partial | Facts and dimensions related; Returns linked 1:1 to Orders (second link to Products inactive) |
| FR19 | Date dimension | **Open** | |
| FR20 | DAX measures | Partial | 5 of the 6 named areas; no growth or category-share measure |
| FR21 | ≥4 report pages | **Open** | 2 pages |
| FR22 | Slicers: Date, Region, Category, Channel, Segment | Partial | Region, Channel, Segment on *Home*; Date range and Category missing |
| FR23 | Drill-through | **Open** | |
| FR24 | Consistent theme / layout | Met | |
| NFR1 | No duplicate keys / ISO dates | Met | Enforced by primary keys and `DATE` types |
| NFR2 | Every number traceable to SQL or DAX | Met | Views + 5 measures |

## 5. Recommended fixes before publishing (priority order)

1. **Quantity outliers (FR9).** 112 lines at quantity 500 are ≈61% of revenue (₹499.9 M of ₹818.2 M), so every revenue KPI depends on this decision. Add a flag and decide whether to keep, cap or exclude; state the choice in the README.
2. **Power BI *Performance* page.** The three slicers are all bound to `Orders[Region]` although two are labelled Channel and Segment; rebind them. Rename the page ("Profermance").
3. **`PaymentMode`.** Apply `TRIM` in the view (or in Orders) so the chart shows 6 values.
4. **Add the missing analyses** if you want the README's coverage table to read "Met": window-function queries on `vw_RevenueTrend`, a Date table with MoM/YoY measures, and the two extra report pages.
5. **Hygiene.** The `.pbix` stores the source server name of your local machine (`SQLEXPRESS` instance); this is harmless but reviewers must repoint it (the README explains how). Complete the cleaning log (and rename the sheet "(template)"). Add 2–3 dashboard screenshots to `docs/` and link them from the README.
