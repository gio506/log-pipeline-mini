#!/usr/bin/env bash
set -euo pipefail

mkdir -p artifacts

echo "[1/5] compose up"
docker compose up -d --build

echo "[2/5] health checks"
docker compose ps
for i in {1..30}; do
  if curl -fsS http://localhost:9200/_cluster/health >/dev/null; then
    break
  fi
  sleep 2
done
curl -fsS http://localhost:9200/_cluster/health | tee artifacts/cluster-health.json >/dev/null

echo "[3/5] send test logs"
docker compose exec -T sample-app python - <<'PY'
import datetime, json
print(json.dumps({
  "@timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
  "app": "orders-api",
  "service": "checkout",
  "env": "local",
  "level": "INFO",
  "route": "/orders/manual",
  "status": 200,
  "latency_ms": 42,
  "trace_id": "tr-manual-001",
  "message": "manual log injection from pipeline stage"
}))
PY

echo "[4/5] verify index exists"
sleep 5
curl -fsS "http://localhost:9200/_cat/indices/app-logs*?v" | tee artifacts/indexes.txt >/dev/null

echo "[5/5] export minimal config lint"
docker compose config > artifacts/compose.resolved.yml
echo "service ready: OpenSearch http://localhost:9200 | Dashboards http://localhost:5601"
echo "cleanup: docker compose down -v"
