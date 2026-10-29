#!/usr/bin/env python3
"""Check tracked UrbanCart source files; requires only the Python standard library."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    "README.md", "CONTRIBUTING.md", "CHANGELOG.md",
    "data/README.md", "powerbi/README.md",
    "docs/SETUP.md", "docs/ARCHITECTURE.md",
    "docs/METRICS.md", "docs/DATA_QUALITY.md",
    "docs/ROADMAP.md", "docs/ASSET_MANIFEST.md",
    "sql/01_schema_and_load.sql", "sql/02_analysis_and_views.sql",
    "sql/03_advanced_analytics.sql",
]
errors = []
for name in FILES:
    path = ROOT / name
    ok = path.is_file() and path.stat().st_size > 100
    print(("PASS" if ok else "FAIL"), name, "non-empty" if ok else "missing or too small")
    if not ok:
        errors.append(name)

if not errors:
    sql = (ROOT / "sql/01_schema_and_load.sql").read_text()
    views = (ROOT / "sql/02_analysis_and_views.sql").read_text()
    advanced = (ROOT / "sql/03_advanced_analytics.sql").read_text()
    checks = {
        "transaction rollback": "ROLLBACK TRANSACTION" in sql,
        "ranked duplicate control": "ROW_NUMBER()" in sql and "DELETE FROM Ranked WHERE rn > 1" in sql,
        "view inventory": views.count("CREATE OR ALTER VIEW") == 9,
        "safe distinct orders": "COUNT(DISTINCT o.OrderID)" in views,
        "window analytics": "LAG(" in advanced and "DENSE_RANK()" in advanced,
        "asset transparency": "not yet committed" in (ROOT / "docs/ASSET_MANIFEST.md").read_text().lower(),
    }
    for item, ok in checks.items():
        print(("PASS" if ok else "FAIL"), item)
        if not ok:
            errors.append(item)

print("RESULT:", "PASS" if not errors else "FAIL")
sys.exit(bool(errors))
