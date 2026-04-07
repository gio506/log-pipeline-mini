# OpenSearch Query Reference

Useful DSL and KQL queries for debugging and monitoring via the Discover / Dev Tools interface.

## Connect to OpenSearch

After `docker compose up -d`:

```bash
# Dev Tools console
open http://localhost:5601/app/dev_tools

# API direct
curl -ku admin:admin http://localhost:9200/_cat/indices
```

---

## Most Useful Queries

### All errors in the last hour

```json
GET app-logs-*/_search
{
  "query": {
    "bool": {
      "must": [
        { "term": { "level.keyword": "ERROR" } }
      ],
      "filter": [
        { "range": { "timestamp": { "gte": "now-1h" } } }
      ]
    }
  },
  "sort": [{ "timestamp": { "order": "desc" } }]
}
```

### Top 10 slowest endpoints (last 24h)

```json
GET app-logs-*/_search
{
  "aggs": {
    "by_path": {
      "terms": { "field": "http_path.keyword", "size": 10 },
      "aggs": {
        "avg_latency": { "avg": { "field": "latency_ms" } }
      }
    }
  },
  "query": {
    "range": { "timestamp": { "gte": "now-24h" } }
  }
}
```

### 5xx Errors by service

```json
GET app-logs-*/_search
{
  "aggs": {
    "by_service": {
      "terms": { "field": "service.keyword" },
      "aggs": {
        "error_count": {
          "filter": { "range": { "http_status": { "gte": 500 } } }
        }
      }
    }
  }
}
```

### Find all events for a specific trace ID

```json
GET app-logs-*/_search
{
  "query": {
    "term": { "trace_id.keyword": "abc123def456" }
  },
  "sort": [{ "timestamp": { "order": "asc" } }]
}
```

---

## KQL (Kibana Query Language) — Quick Filters

Use in the Discover search bar:

```text
# Errors only
level: ERROR

# Errors from specific service
level: ERROR AND service: api-gateway

# Slow requests (> 500ms)
latency_ms > 500

# 4xx/5xx status codes
http_status >= 400

# Specific path with errors
http_path: "/api/v1/orders" AND http_status >= 500
```

---

## Troubleshooting Index Issues

```bash
# Check shard health
curl -ku admin:admin http://localhost:9200/_cluster/health?pretty

# List all indices with doc counts
curl -ku admin:admin http://localhost:9200/_cat/indices?v&h=index,health,docs.count

# Check logs pipeline (Fluent Bit → OpenSearch)
curl -ku admin:admin http://localhost:9200/app-logs-*/_count

# Flush manually if writes are stuck
curl -ku admin:admin -X POST http://localhost:9200/app-logs-*/_flush
```
