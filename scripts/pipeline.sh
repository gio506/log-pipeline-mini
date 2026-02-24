#!/usr/bin/env bash
set -euo pipefail

mkdir -p artifacts

echo "[1/6] compose up"
docker compose up -d --build

echo "[2/6] health checks"
docker compose ps
for i in {1..30}; do
  if curl -fsS http://localhost:9200/_cluster/health >/dev/null; then
    break
  fi
  sleep 2
done
curl -fsS http://localhost:9200/_cluster/health | tee artifacts/cluster-health.json >/dev/null

echo "[3/6] send test logs"
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

echo "[4/6] verify index exists"
sleep 5
curl -fsS "http://localhost:9200/_cat/indices/app-logs*?v" | tee artifacts/indexes.txt >/dev/null

echo "[5/6] export minimal config lint"
docker compose config > artifacts/compose.resolved.yml

echo "[6/6] done (cleanup is manual: docker compose down -v)"
