# Structured Log Schema

This document defines the log fields emitted by the demo application and ingested into OpenSearch via Fluent Bit.

## Log Format

All log lines are JSON-structured:

```json
{
  "timestamp": "2025-04-07T14:32:01.123Z",
  "level": "INFO",
  "service": "api-gateway",
  "trace_id": "abc123def456",
  "span_id": "f1a2b3",
  "http_method": "POST",
  "http_path": "/orders",
  "http_status": 201,
  "latency_ms": 42,
  "user_id": "usr_8f2k1",
  "message": "order created successfully"
}
```

---

## Field Definitions

| Field | Type | Description | Example |
|---|---|---|---|
| `timestamp` | ISO 8601 | UTC time of the event | `2025-04-07T14:32:01Z` |
| `level` | string | Log level | `INFO`, `WARN`, `ERROR` |
| `service` | string | Service name | `api-gateway`, `worker` |
| `trace_id` | string | Distributed trace identifier | `abc123def456` |
| `http_method` | string | HTTP verb | `GET`, `POST`, `DELETE` |
| `http_path` | string | Request path (no query string) | `/api/v1/users` |
| `http_status` | int | HTTP response code | `200`, `404`, `500` |
| `latency_ms` | int | Request duration in milliseconds | `42` |
| `message` | string | Human-readable event description | `user login failed` |

---

## Log Levels — When to Use Each

| Level | Use Case | Alert? |
|---|---|---|
| `DEBUG` | Fine-grained diagnostic data. Disabled in production. | No |
| `INFO` | Normal operations (request received, cache hit). | No |
| `WARN` | Recoverable conditions (rate limit approaching, slow query). | Maybe |
| `ERROR` | Failures that need attention (DB connection refused). | Yes |
| `FATAL` | Non-recoverable — process will exit after logging. | Yes (pager) |

---

## Fluent Bit Pipeline

```text
[INPUT: tail /var/log/app.log]
        ↓
[FILTER: parser — parse JSON]
        ↓
[FILTER: grep — drop level=DEBUG if env=prod]
        ↓
[FILTER: modify — add cluster_name field]
        ↓
[OUTPUT: opensearch — index=app-logs-YYYY.MM.DD]
```

Index pattern uses daily rotation to control shard size and simplify retention policy (ILM).

---

## Retention Policy

- **dev logs**: 7 days (hot tier only)
- **staging logs**: 30 days (7 hot, 23 warm)
- **production logs**: 90 days (7 hot, 30 warm, 53 cold)
