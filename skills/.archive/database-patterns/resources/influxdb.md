# InfluxDB — Time-Series Database

High-performance time-series database for IoT, metrics, observability.

## Quick Reference

| Concept | Description |
|---------|-------------|
| **Measurement** | Like a table |
| **Tag** | Indexed metadata (device_id, location) |
| **Field** | Data values (temperature, humidity) |
| **Timestamp** | UTC nanoseconds |
| **Bucket** | Container for data (replaces database) |
| **Retention Policy** | How long data lives |

## InfluxQL vs Flux

**InfluxQL** — SQL-like, simpler queries.
**Flux** — Functional, more powerful, recommended for new projects.

## Connection & Write (Python)

```python
from influxdb_client import InfluxDBClient, Point, WriteOptions

client = InfluxDBClient(
    url="http://localhost:8086",
    token="my-token",
    org="my-org"
)

# Write single point
point = Point("sensor_data") \
    .tag("device_id", "sensor-001") \
    .tag("location", "warehouse-a") \
    .field("temperature", 23.5) \
    .field("humidity", 65.2) \
    .time(time.time_ns())

with client.write_api() as writer:
    writer.write(bucket="sensors", org="my-org", record=point)

# Batch write
points = [
    Point("sensor_data").tag("device_id", f"sensor-{i:03d}").field("temp", random.random() * 100)
    for i in range(100)
]
with client.write_api(write_options=WriteOptions(batch_size=500)) as writer:
    writer.write(bucket="sensors", org="my-org", record=points)
```

## Query (Flux)

```python
query = '''
from(bucket: "sensors")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "sensor_data")
  |> filter(fn: (r) => r["device_id"] == "sensor-001")
  |> aggregateWindow(every: 5m, fn: mean)
  |> yield(name: "mean")
'''

result = client.query_api().query(query, org="my-org")

# Process results
for table in result:
    for row in table.records:
        print(f"{row['_time']}: {row['_value']}")
```

## Schema Design

**For IoT sensors:**
```
Measurement: environmental
Tags (high cardinality → indexed): device_id, location, floor, building
Fields: temperature, humidity, pressure, co2
Timestamp: server-generated
```

**Design rules:**
- Tag values with low cardinality for queries
- Field values can have high cardinality
- Timestamp precision: use seconds for normal, nanoseconds for HFT

## Retention Policies

```flux
// Define retention policy
option retention = {
  name: "10year",
  period: 3650d
}

// Downsample old data (continuous query)
from(bucket: "sensors")
  |> range(start: -30d)
  |> aggregateWindow(every: 1h, fn: mean)
  |> to(bucket: "sensors_30d_avg")
```

## Telegraf Integration

```toml
# telegraf.conf
[[inputs.mqtt_consumer]]
  servers = ["tcp://mqtt-broker:1883"]
  topics = ["sensors/#"]

[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "$INFLUX_TOKEN"
  organization = "my-org"
  bucket = "sensors"
```

## Downsampling (CQ)

```sql
-- Create continuous query for 1-minute → 1-hour aggregates
CREATE CONTINUOUS QUERY "downsample_1h" ON "sensors"
BEGIN
  SELECT mean(temperature), mean(humidity)
  INTO "sensors_1h"
  FROM "environmental"
  GROUP BY time(1h), device_id, location
END
```

## HTTP API (curl)

```bash
# Write
curl -X POST http://localhost:8086/api/v2/write \
  -H "Authorization: Token my-token" \
  -H "Content-Type: text/plain" \
  --data-binary "environmental,device=sensor-001 temp=23.5 1699999999000000000"

# Query
curl -X POST http://localhost:8086/api/v2/query \
  -H "Authorization: Token my-token" \
  -H "Content-Type: application/vnd.flux" \
  -d 'from(bucket:"sensors") |> range(start:-1h)'
```

## Comparison

| Feature | InfluxDB | TimescaleDB | Prometheus |
|---------|----------|------------|------------|
| Type | Time-series | Time-series (PostgreSQL) | Metrics |
| Best for | IoT, events | General TSDB | Monitoring |
| Retention | Configurable | Configurable | Short |
| Query | Flux/SQL | SQL | PromQL |
| Scale | High | High | Medium |

## Resources

- [awesome-influxdb](https://github.com/mark-rushakoff/awesome-influxdb)
- [influxdb.com/docs](https://docs.influxdata.com/influxdb/)