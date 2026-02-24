import datetime
import json
import os
import random
import time

app_name = os.getenv("APP_NAME", "orders-api")
log_file = os.getenv("LOG_FILE", "/var/log/app/app.log")
os.makedirs(os.path.dirname(log_file), exist_ok=True)

levels = ["INFO", "WARN", "ERROR"]
routes = ["/orders", "/orders/checkout", "/orders/status", "/payments"]

while True:
    record = {
        "@timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "app": app_name,
        "service": "checkout",
        "env": "local",
        "level": random.choices(levels, weights=[0.8, 0.15, 0.05], k=1)[0],
        "route": random.choice(routes),
        "status": random.choices([200, 201, 400, 500], weights=[0.65, 0.15, 0.1, 0.1], k=1)[0],
        "latency_ms": random.randint(20, 950),
        "trace_id": f"tr-{random.randint(10_000, 99_999)}",
        "message": "sample event from app container",
    }
    line = json.dumps(record)
    print(line, flush=True)
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(line + "\n")
    time.sleep(2)
