#!/usr/bin/env bash
set -euo pipefail

ARTIFACT_DIR="artifacts"
mkdir -p "${ARTIFACT_DIR}"

require_vm_max_map_count() {
  local current
  current=$(sysctl -n vm.max_map_count 2>/dev/null || echo 0)
  if [[ "${current}" -lt 262144 ]]; then
    echo "ERROR: vm.max_map_count=${current} is too low; set it to at least 262144." >&2
    echo "Fix: sudo sysctl -w vm.max_map_count=262144" >&2
    return 1
  fi
}

wait_for_http() {
  local url="$1"
  local attempts="${2:-45}"
  local sleep_s="${3:-2}"
  local i

  for ((i=1; i<=attempts; i++)); do
    if curl -fsS "$url" >/dev/null; then
      return 0
    fi
    sleep "$sleep_s"
  done

  echo "ERROR: timed out waiting for $url" >&2
  return 1
}

echo "[1/5] preflight checks"
require_vm_max_map_count

echo "[2/5] compose up"
docker compose up -d --build

echo "[3/5] health checks"
docker compose ps
wait_for_http "http://localhost:9200/_cluster/health"
wait_for_http "http://localhost:5601/api/status"
curl -fsS "http://localhost:9200/_cluster/health" | tee "${ARTIFACT_DIR}/cluster-health.json" >/dev/null

echo "[4/5] send test logs"
docker compose exec -T sample-app python - <<'PY'
import datetime
import json

record = {
  "@timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
  "app": "orders-api",
  "service": "checkout",
  "env": "local",
  "level": "INFO",
  "route": "/orders/manual",
  "status": 200,
  "latency_ms": 42,
  "trace_id": "tr-manual-001",
  "message": "manual log injection from pipeline stage",
}
line = json.dumps(record)

print(line, flush=True)
with open("/var/log/app/app.log", "a", encoding="utf-8") as f:
    f.write(line + "\n")
PY

echo "[5/5] verify index + document visibility"
for _ in {1..30}; do
  if curl -fsS "http://localhost:9200/_cat/indices/app-logs*?v" | tee "${ARTIFACT_DIR}/indexes.txt" | grep -q "app-logs"; then
    break
  fi
  sleep 2
done
curl -fsS "http://localhost:9200/app-logs*/_count" | tee "${ARTIFACT_DIR}/doc-count.json" >/dev/null

echo "export compose lint + ready summary"
docker compose config > "${ARTIFACT_DIR}/compose.resolved.yml"
echo "service ready: OpenSearch http://localhost:9200 | Dashboards http://localhost:5601"
echo "cleanup: docker compose down -v"
