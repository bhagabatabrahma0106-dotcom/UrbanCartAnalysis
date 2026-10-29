#!/usr/bin/env python3
"""Validate committed UrbanCart source files and uploaded asset identities.

Static checks only. This does not execute SQL Server or open Power BI Desktop.
"""
from pathlib import Path
import hashlib
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
TEXT = [
    "README.md", "CONTRIBUTING.md", "CHANGELOG.md",
    "data/README.md", "powerbi/README.md",
    "docs/SETUP.md", "docs/ARCHITECTURE.md",
    "docs/METRICS.md", "docs/DATA_QUALITY.md",
    "docs/ROADMAP.md", "docs/ASSET_MANIFEST.md",
    "docs/archive/REVIEW_NOTES.md",
    "sql/01_schema_and_load.sql", "sql/02_analysis_and_views.sql",
    "sql/03_advanced_analytics.sql",
]
# Intentional release identities: (file length in bytes, Git blob object SHA-1).
ASSETS = {
    "data/raw/UrbanCart_Raw_Sales_Data.xlsx": (1831619, "96456c4945a1529a31fabaf742a6d6d2d2152275"),
    "data/cleaned/UrbanCart_Cleaned_Sales_Data.xlsx": (2949454, "2ccc0710e3455f6706a9831677bc9ae8d0315fa8"),
    "powerbi/UrbanCart_Dashboard.pbix": (1662323, "7e8c21a84e013469aae2109da88571b3a0edb6e1"),
    "docs/UrbanCart_Business_Requirement_Document.docx": (15981, "16c6549d080549b6493d81a852fa1f74204a3af7"),
    "docs/UrbanCart_Project_Walkthrough.pptx": (65605, "105ef020977ad52439e13d821df5ac9df6af83a6"),
    "docs/UrbanCart_Dashboard_Reference.html": (605436, "52302595a6f8e4eb3f486b8cf527a9a047ebb933"),
}
errors = []
for name in TEXT:
    file = ROOT / name
    valid = file.is_file() and file.stat().st_size > 100
    print(("PASS" if valid else "FAIL"), name)
    if not valid:
        errors.append(name)

for name, (size, blob_id) in ASSETS.items():
    file = ROOT / name
    valid = file.is_file()
    if valid:
        data = file.read_bytes()
        actual_id = hashlib.sha1(f"blob {len(data)}\0".encode() + data).hexdigest()
        valid = len(data) == size and actual_id == blob_id
    print(("PASS" if valid else "FAIL"), name, "uploaded bytes")
    if not valid:
        errors.append(name)

if not errors:
    sql = (ROOT / "sql/01_schema_and_load.sql").read_text(encoding="utf-8")
    views = (ROOT / "sql/02_analysis_and_views.sql").read_text(encoding="utf-8")
    advanced = (ROOT / "sql/03_advanced_analytics.sql").read_text(encoding="utf-8")
    checks = {
        "guarded SQL transaction": "ROLLBACK TRANSACTION" in sql,
        "staging duplicate control": "ROW_NUMBER()" in sql and "DELETE FROM Ranked WHERE rn > 1" in sql,
        "nine reporting views": views.count("CREATE OR ALTER VIEW") == 9,
        "distinct order aggregation": "COUNT(DISTINCT o.OrderID)" in views,
        "advanced window queries": "LAG(" in advanced and "DENSE_RANK()" in advanced,
        "committed asset manifest": "# Committed asset manifest" in (ROOT / "docs/ASSET_MANIFEST.md").read_text(encoding="utf-8"),
    }
    for label, valid in checks.items():
        print(("PASS" if valid else "FAIL"), label)
        if not valid:
            errors.append(label)

try:
    tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).split(b"\0")
    for raw_name in tracked:
        if not raw_name:
            continue
        file = ROOT / raw_name.decode("utf-8")
        if not file.is_file() or file.stat().st_size == 0:
            errors.append(f"missing or empty tracked file: {file.relative_to(ROOT)}")
except (OSError, subprocess.CalledProcessError) as exc:
    print("INFO: git tracked-file check unavailable:", exc)

print("RESULT:", "PASS" if not errors else "FAIL: " + ", ".join(errors))
sys.exit(bool(errors))
