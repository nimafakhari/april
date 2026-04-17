# april

This project includes a simple Python Redis counter app plus an ELK stack for log collection.

## Run locally with ELK

1. Build and start the app stack:

   ```bash
   docker compose up --build
   ```

2. Open the app:

   - http://localhost:8000

3. Open Kibana:

   - http://localhost:5601

4. Generate traffic by refreshing the app page, then use Kibana Discover to search `app-logs-*`.

## Services

- `app`: Python counter app
- `redis`: Redis database
- `elasticsearch`: Elasticsearch store
- `logstash`: Logstash pipeline
- `filebeat`: Collects app logs and sends them to Logstash
- `kibana`: Kibana UI for searching logs

## Logs

The app writes log events to `logs/app.log`. Filebeat reads that file and forwards logs into Elasticsearch.
