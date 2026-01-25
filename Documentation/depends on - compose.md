# Docker Compose depends_on with Healthchecks

## Make Backend Wait for MongoDB

Update your backend service in `docker-compose.yml`:

```yaml
backend:
  build: ./backend
  container_name: infra-health-backend
  ports:
    - "8000:8000"
  depends_on:
    mongo:
      condition: service_healthy
```

## Result

- Backend starts **only after** MongoDB is healthy
- No race conditions between services
- DNS + connection both work properly

## Why This Matters

Without `condition: service_healthy`:

- Backend might start before MongoDB is ready
- Connection errors and crashes

With healthcheck condition:

- Docker ensures MongoDB is accepting connections
- Backend starts with a healthy database connection
