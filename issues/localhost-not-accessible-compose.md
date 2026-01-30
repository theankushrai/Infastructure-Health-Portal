# Localhost Not Accessible in Docker Compose

## Problem

Services cannot connect to each other using `localhost` in Docker Compose.

## Root Cause

In Docker Compose:

- ❌ `localhost` does NOT work between containers
- ✅ Containers communicate using **service names**

## Solution

### Update MongoDB Connection Strings

Replace `localhost` with service name `mongo`:

#### In Backend Files

Files to update:

- `backend/app/main.py`
- `backend/app/tasks.py`
- `backend/app/celery_app.py`

**Before:**

```python
MongoClient("mongodb://localhost:27017")
```

**After:**

```python
MongoClient("mongodb://mongo:27017")
```

#### In Celery Configuration

**Before:**

```python
broker="mongodb://localhost:27017/infra_health",
backend="mongodb://localhost:27017/infra_health",
```

**After:**

```python
broker="mongodb://mongo:27017/infra_health",
backend="mongodb://mongo:27017/infra_health",
```

## Why This Works

- `mongo` is the **service name** defined in `docker-compose.yml`
- Docker provides automatic DNS resolution between services
- Each service can reach others using their service names

## Docker Compose Service Names

Based on your `docker-compose.yml`:

- `mongo` → MongoDB service
- `backend` → FastAPI service
- `worker` → Celery worker service
- `frontend` → React/Nginx service

## Example docker-compose.yml Reference

```yaml
services:
  mongo:
    image: mongo:6
    # Service name is "mongo"

  backend:
    build: ./backend
    # Can reach mongo at "mongo:27017"
```

## Key Points

- **Service names = DNS names** in Docker networks
- **localhost** refers to the container itself, not other services
- This pattern applies to both Docker Compose and Kubernetes
