---
description: "April project — Python Redis counter app with Docker and Kubernetes"
---

# April Project — Workspace Instructions

## Project Overview

**April** is a lightweight Python HTTP server that maintains a Redis-backed counter. It demonstrates containerization, orchestration, and CI/CD automation patterns.

- **Core App**: `app.py` — Python HTTP server (http.server module) with Redis integration
- **Runtime**: Python 3.11, Redis 7
- **Deployment**: Docker, Docker Compose (local), Kubernetes (production)
- **CI/CD**: Jenkins pipeline
- **Testing**: pytest with coverage reporting

## Quick Reference

### Development Setup
```bash
# Create virtual environment and install dependencies
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Run the app locally (requires Redis on localhost:6379)
python app.py

# Run tests
pytest tests/ -v --cov=app
```

### Local Deployment
```bash
# Start Redis and app via Docker Compose
docker-compose up --build

# Access the app at http://localhost:8000
```

### Architecture Decisions

| Component | Choice | Rationale |
|-----------|--------|-----------|
| HTTP Server | Built-in `http.server` | Minimal dependencies, educational clarity |
| Web Framework | None (raw HTTP) | Direct control, single-responsibility |
| Database | Redis | Fast key-value store for counter state |
| Container Runtime | Docker | Standard for microservices |
| Orchestration | Kubernetes | Production-grade workload management |

## File Structure

```
├── app.py                 # Main application
├── requirements.txt       # Python dependencies (redis>=4.7.0)
├── docker-compose.yml     # Local multi-container setup
├── Dockerfile             # Container image definition
├── Jenkinsfile           # CI/CD pipeline (Jenkins)
├── k8s/                  # Kubernetes manifests
│   ├── namespace.yml
│   ├── app-deployment.yml
│   └── redis-deployment.yml
├── tests/                # Test suite (pytest)
└── test-results/         # Coverage reports (auto-generated)
```

## Key Conventions

### Environment Variables
The app reads Redis connection from environment variables:
- `REDIS_HOST` (default: `localhost`)
- `REDIS_PORT` (default: `6379`)

These are set in `docker-compose.yml` and K8s manifests.

### Deployment Workflow
1. **Local Dev**: `docker-compose up` for quick iteration
2. **Testing**: Jenkins pipeline runs pytest with coverage
3. **Build**: Jenkins creates Docker image, tags with build number
4. **Deploy**: CD system applies K8s manifests to cluster

### Code Quality
- Coverage reports generated in `test-results/`
- All new features should include unit tests
- K8s YAML follows standard conventions (metadata, spec, status)

## Common Tasks

### Add a New Endpoint
Edit `app.py` — add a `do_GET()` or `do_POST()` handler method in `CounterHandler` class.

### Update Dependencies
1. Edit `requirements.txt`
2. Run `pip install -r requirements.txt` to update local venv
3. Dockerfile will pick up changes on next build

### Deploy to Kubernetes
```bash
kubectl apply -f k8s/namespace.yml
kubectl apply -f k8s/redis-deployment.yml
kubectl apply -f k8s/app-deployment.yml
```

### View Logs
```bash
# Docker Compose
docker-compose logs app

# Kubernetes
kubectl logs -f deployment/app -n april
```

## Debugging Tips

- **Redis connection issues**: Check `REDIS_HOST` and `REDIS_PORT` environment variables
- **Port conflicts**: The app defaults to port 8000; change in `app.py` or via Docker port mappings
- **Test coverage**: Open `test-results/index.html` after running pytest to see coverage gaps

## Related Documentation

- [K8s README](./k8s/README.md) — Kubernetes deployment details
- [Jenkins Pipeline](./Jenkinsfile) — CI/CD stages and environment variables
- [Docker Compose Setup](./docker-compose.yml) — Local dev environment
