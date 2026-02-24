# log-pipeline-mini

A mini local logging pipeline for structured JSON logs using **Fluent Bit -> OpenSearch -> OpenSearch Dashboards** with Docker Compose.

This repo keeps the original concept (simple, local, demo-friendly) but hardens execution with better health checks, CI stages, and operational runbooks.

## Architecture
1. `sample-app` emits JSON logs to stdout and `/var/log/app/app.log`.
2. `fluent-bit` tails `/var/log/app/app.log` and forwards documents to OpenSearch.
3. `opensearch` stores/indexes logs under `app-logs*`.
4. `dashboards` lets you search and visualize events.

## Project tree
```text
.
├── .github/workflows/pipeline-checker.yml  # 6-stage CI checker (lint + readiness run + cleanup)
├── docker-compose.yml                       # Services: OpenSearch, Dashboards, sample-app, Fluent Bit
├── fluent-bit/
│   └── fluent-bit.conf                      # Tail input + OpenSearch output
├── sample-app/
│   ├── Dockerfile                           # Python container image
│   └── app.py                               # Continuous JSON log emitter
├── scripts/
│   └── pipeline.sh                          # 5-stage local readiness pipeline
├── CHEATSHEET.md                            # Fast operational commands
├── .gitignore                               # Ignore caches and generated artifacts
└── artifacts/                               # Generated runtime outputs from checks (created on run)
```

## Quick start
```bash
docker compose up -d --build
```

Endpoints:
- OpenSearch: <http://localhost:9200>
- Dashboards: <http://localhost:5601>

## 5-stage readiness pipeline
Run:
```bash
./scripts/pipeline.sh
```

What it does:
1. **Preflight**: validates `vm.max_map_count` host kernel requirement for OpenSearch.
2. **Compose up**: starts all services.
3. **Health checks**: waits for OpenSearch and Dashboards APIs.
4. **Send test logs**: injects a manual JSON event into app log file.
5. **Verify ingestion + lint export**: confirms `app-logs*`, writes doc count artifact, exports compose config, and prints ready/cleanup hints.

Artifacts produced:
- `artifacts/cluster-health.json`
- `artifacts/indexes.txt`
- `artifacts/doc-count.json`
- `artifacts/compose.resolved.yml`

## Manual verification commands
```bash
# cluster health
curl -s http://localhost:9200/_cluster/health | jq

# indices
curl -s 'http://localhost:9200/_cat/indices/app-logs*?v'

# count docs
curl -s 'http://localhost:9200/app-logs*/_count' | jq
```

## OpenSearch query examples (Dev Tools)
```json
GET app-logs*/_count
```

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

## CI pipeline checker (GitHub Actions)
Workflow: `.github/workflows/pipeline-checker.yml`

Stages:
1. Checkout
2. Setup Python
3. Static checks (`bash -n`, `py_compile`)
4. Compose lint (`docker compose config`)
5. Run local 5-stage readiness script
6. Validate artifacts + cleanup

## Cleanup
```bash
docker compose down -v --remove-orphans
```

## References (official docs)
- Docker Compose: <https://docs.docker.com/compose/>
- Fluent Bit docs: <https://docs.fluentbit.io/manual>
- OpenSearch docs: <https://docs.opensearch.org/latest/>
- OpenSearch Dashboards docs: <https://docs.opensearch.org/latest/dashboards/>
- GitHub Actions docs: <https://docs.github.com/actions>


## Troubleshooting
If OpenSearch exits immediately with code `1`, the most common cause is low `vm.max_map_count`.

Fix:
```bash
sudo sysctl -w vm.max_map_count=262144
```
Then rerun:
```bash
./scripts/pipeline.sh
```
