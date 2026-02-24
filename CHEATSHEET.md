# CHEATSHEET

Quick commands for operating the mini logging pipeline.

## Start / Stop
- `docker compose up -d --build` → start all services
- `docker compose down -v --remove-orphans` → stop + clean containers/volumes

## Readiness script
- `./scripts/pipeline.sh` → runs the full 5-stage readiness workflow

## Health
- `docker compose ps` → service status
- `curl -s localhost:9200/_cluster/health | jq` → OpenSearch cluster health
- `curl -s localhost:5601/api/status | jq '.status.overall'` → Dashboards health

## Ingestion checks
- `curl -s 'localhost:9200/_cat/indices/app-logs*?v'` → index existence
- `curl -s 'localhost:9200/app-logs*/_count' | jq` → ingested document count
- `docker compose logs -f fluent-bit` → shipper logs

## Compose lint / render
- `mkdir -p artifacts && docker compose config > artifacts/compose.resolved.yml`

## Artifacts from pipeline
- `artifacts/cluster-health.json` → OpenSearch health snapshot
- `artifacts/indexes.txt` → index listing for `app-logs*`
- `artifacts/doc-count.json` → count API response for ingested docs
- `artifacts/compose.resolved.yml` → resolved compose config


## Optional env override
- `export OPENSEARCH_INITIAL_ADMIN_PASSWORD='your-strong-password'` → set local password quickly
- or create a local `.env` file with `OPENSEARCH_INITIAL_ADMIN_PASSWORD=...`
