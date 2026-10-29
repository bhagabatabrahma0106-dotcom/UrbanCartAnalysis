# Metric dictionary

| Metric | Logic | Grain / caveat |
|---|---|---|
| Gross sales | `SUM(Order_Items.LineTotal)` | Excludes refunds and shipping; includes flagged quantities |
| Orders | `COUNT(DISTINCT Orders.OrderID)` | Distinct order ID |
| Customers | `COUNT(DISTINCT Customers.CustomerID)` | All customer records; ordering customers are a different metric |
| Average order value | Gross sales / distinct orders | Gross of refunds |
| Returning customers | Customers with at least 2 orders | Based on observed period |
| Order return rate | Distinct orders with return / distinct orders | Not unit return rate |
| Delivery days | `DATEDIFF(day, ShipDate, DeliveryDate)` | Valid non-null date pairs only |
| Month-over-month growth | `(current - prior) / prior` | Null if no meaningful prior month |
| Year-over-year growth | `(current - same month last year) / last year` | Only when comparable month is present |

Amounts are INR, not USD. Synthetic source data contains anomalies, so illustrative KPIs are not certified financial results.
