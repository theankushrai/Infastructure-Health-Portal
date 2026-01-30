# MongoDB Not Accessible in Docker Compose

## Problem

Backend fails to connect to MongoDB with error:

```
No address associated with hostname mongo
```

## Root Cause

**Service startup timing issue:**

- `depends_on` only means "Mongo container was started"
- MongoDB needs time to initialize before accepting connections
- Backend tries to connect too early
- DNS exists but Mongo isn't ready → connection fails

## Solution

### Step 1: Add MongoDB Healthcheck

Update `docker-compose.yml`:

```yaml
services:
  mongo:
    image: mongo:6
    container_name: infra-health-mongo
    ports:
      - "27017:27017"
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.runCommand('ping').ok"]
      interval: 5s
      timeout: 5s
      retries: 5
```

### Step 2: Make Backend Wait for Health

Update backend service:

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

### Step 3: Clean Restart

Remove old containers and restart:

```bash
docker-compose down
docker-compose up --build
```

## Expected Behavior

You should see logs like:

```
mongo    | Waiting for connections
mongo    | ... healthy
backend  | Uvicorn running on http://0.0.0.0:8000
```

## Test the Fix

- Visit `http://localhost:8000/health`
- Try POST `/jobs`
- Backend should stay running without crashes

## Key Points

- **Healthchecks ensure services are actually ready**
- **Conditional depends_on prevents race conditions**
- **This is the production-standard approach**

## What NOT to Do

❌ Don't add `time.sleep(10)` in code  
❌ Don't retry infinitely without control  
❌ Don't blame DNS

## Interview Answer

> "I use healthchecks and conditional `depends_on` to ensure services only start when their dependencies are actually ready."
