# Files Explained

- `.github/workflows/pipeline-checker.yml`: 6-stage CI checker for static checks, compose validation, smoke execution, and cleanup.
- `CHEATSHEET.md`: quick operational commands for the logging stack.
- `FILES_EXPLAINED.md`: short purpose statement for every tracked file.
- `README.md`: project overview, runbook, smoke steps, and troubleshooting.
- `docker-compose.yml`: Compose stack for OpenSearch, Dashboards, sample app, and Fluent Bit.
- `fluent-bit/fluent-bit.conf`: tail input and OpenSearch output pipeline.
- `sample-app/Dockerfile`: image build for the sample JSON logging app.
- `sample-app/app.py`: continuous JSON log emitter.
- `scripts/pipeline.sh`: main 5-step local readiness pipeline.
- `scripts/smoke.sh`: wrapper entrypoint expected by the dev workflow.
