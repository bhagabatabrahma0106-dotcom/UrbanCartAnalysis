# Contributing

This portfolio repository accepts improvements that preserve analytical integrity.

1. Open an issue describing the defect or proposed change.
2. Use a focused branch and a pull request; avoid force pushing to `main`.
3. Include what changed, why, how you verified it, and any data-model or metric implications.
4. Never commit credentials, personal information or exported client/production data.
5. Run `python scripts/validate_repository.py` before submitting.
6. If changing SQL, include a tested query plan or execution note and confirm the result against source data.
7. If changing Power BI, report Desktop version, data-source parameters and refresh validation.

No code review or CI result can substitute for checking business definitions and dataset provenance.
