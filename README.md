# Redis Counter - C# Version

A Redis counter web application built with **C# and .NET 8**.

## Features

- 🔢 Increment/decrement counter
- 👁️ View counter without incrementing
- 🔄 Reset counter to 0
- ⚙️ Set custom value
- 🐳 Docker & Docker Compose support
- 🚀 Similar functionality to the Python version

## Prerequisites

- .NET 8 SDK (for local development)
- Docker & Docker Compose (for containerized deployment)
- Redis server (or use docker-compose)

## Local Development

```bash
# Restore dependencies
dotnet restore

# Run the application
dotnet run
```

Access the app at `http://localhost:8000`

## Docker Deployment

### Build and Run with Docker Compose

```bash
docker compose up -d --build
```

This will start:
- Redis server on port 6379
- C# app on port 8000

### Access the Application

Open your browser and navigate to `http://localhost:8000`

### Stop Services

```bash
docker compose down
```

## API Endpoints

- `GET /` - Increment counter
- `GET /decrement` - Decrement counter
- `GET /view` - View counter (no increment)
- `GET /reset` - Reset to 0
- `GET /set?value=X` - Set counter to X

## Environment Variables

- `REDIS_HOST` - Redis server hostname (default: localhost)
- `REDIS_PORT` - Redis server port (default: 6379)

## Architecture

- **Frontend**: HTML with inline CSS and JavaScript
- **Backend**: C# Console Application with HttpListener
- **Database**: Redis (in-memory data store)
- **Framework**: .NET 8

## Comparison with Python Version

| Feature | Python | C# |
|---------|--------|-----|
| Language | Python 3.11 | C# (.NET 8) |
| HTTP Server | BaseHTTPRequestHandler | HttpListener |
| Redis Client | redis-py | StackExchange.Redis |
| Image Size | ~200MB | ~100MB (multi-stage) |
| Performance | Good | Excellent |

## Technology Stack

- **.NET 8**: Modern, high-performance framework
- **StackExchange.Redis**: High-performance Redis client
- **HttpListener**: Built-in HTTP server
- **Docker**: Containerization
- **Alpine Linux**: Minimal base image
