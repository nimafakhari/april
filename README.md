# april
redis
 ├── app
 ├── redis_exporter
 │    └── prometheus
 │         └── grafana
 └── cadvisor
      └── prometheus

⚠️ Important caveat
depends_on only waits for the container to start, not to be ready. For example, Redis may take a moment to accept connections after starting.      