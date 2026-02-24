# CHEATSHEET

Purpose: quick references for operating this mini logging pipeline.

## Boot / Stop
- `docker compose up -d --build` → start whole stack
- `docker compose down -v` → stop and remove volumes

## Health
- `docker compose ps` → container status
- `curl -s localhost:9200/_cluster/health | jq` → OpenSearch health
- `curl -s localhost:5601/api/status | jq '.status.overall'` → Dashboards health

## Logs + Verification
- `docker compose logs -f fluent-bit` → shipper logs
- `curl -s 'localhost:9200/_cat/indices/app-logs*?v'` → check indices
- `curl -s 'localhost:9200/app-logs*/_count'` → count ingested records

## Validation export
- `docker compose config > artifacts/compose.resolved.yml` → resolved compose lint output

## Automation
- `./scripts/pipeline.sh` → runs the 6-stage demo pipeline end-to-end
