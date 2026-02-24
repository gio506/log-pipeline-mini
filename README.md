# log-pipeline-mini

Mini logging pipeline that ships JSON logs from a sample app to OpenSearch with Fluent Bit, then explores them in OpenSearch Dashboards.

## Stack
- Docker Compose orchestration
- Sample Python app emitting JSON logs
- Fluent Bit tail input + OpenSearch output
- OpenSearch for storage/index/search
- OpenSearch Dashboards for visualization

## Project tree
```text
.
├── docker-compose.yml           # Runs OpenSearch, Dashboards, Fluent Bit, and sample app
├── README.md                    # Setup, runbook, queries, dashboard walkthrough
├── CHEATSHEET.md                # Fast commands for daily use
├── fluent-bit/
│   └── fluent-bit.conf          # Input/filter/output pipeline config
├── sample-app/
│   ├── Dockerfile               # Sample app container image
│   └── app.py                   # Emits structured JSON logs continuously
├── scripts/
│   └── pipeline.sh              # 5-stage readiness pipeline script
└── artifacts/                   # Generated outputs (health/index/config snapshots)
```

## Quick start
```bash
docker compose up -d --build
```

Endpoints:
- OpenSearch: http://localhost:9200
- Dashboards: http://localhost:5601

## 5-stage readiness pipeline walkthrough
### 1) Compose up
```bash
docker compose up -d --build
```

### 2) Health checks for services
```bash
docker compose ps
curl -s http://localhost:9200/_cluster/health | jq
curl -s http://localhost:5601/api/status | jq '.status.overall'
```

### 3) Send test logs
The sample app emits logs every 2 seconds. You can also inject one manually:
```bash
docker compose exec -T sample-app python - <<'PY'
import datetime, json
print(json.dumps({
  "@timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
  "app": "orders-api",
  "level": "INFO",
  "message": "manual test event"
}))
PY
```

### 4) Verify index exists
```bash
curl -s "http://localhost:9200/_cat/indices/app-logs*?v"
```

### 5) Export minimal config lint + ready check
```bash
docker compose config > artifacts/compose.resolved.yml
```
This validates and renders the resolved Compose configuration.

When complete, services are ready to use at:
- OpenSearch: `http://localhost:9200`
- Dashboards: `http://localhost:5601`

Cleanup when finished:
```bash
docker compose down -v
```

## Search queries (Dev Tools)
Open Dashboards → **Dev Tools** and run:

Count docs:
```json
GET app-logs*/_count
```

Latest errors:
```json
GET app-logs*/_search
{
  "size": 10,
  "sort": [{"@timestamp": "desc"}],
  "query": {
    "term": {"level.keyword": "ERROR"}
  }
}
```

Slow requests (`latency_ms >= 700`):
```json
GET app-logs*/_search
{
  "size": 20,
  "sort": [{"latency_ms": "desc"}],
  "query": {
    "range": {"latency_ms": {"gte": 700}}
  }
}
```

## Dashboard suggestions (minimal)
1. Create index pattern: `app-logs*` with time field `@timestamp`.
2. Create visualizations:
   - Logs over time (date histogram)
   - Error rate by `level.keyword`
   - Top routes by `route.keyword`
   - P95 latency via percentile on `latency_ms`
3. Save dashboard: `Local Log Pipeline Overview`.

## One-command runbook
```bash
./scripts/pipeline.sh
```
