# Celery Worker Issues

## Common Symptoms

- Job status stuck in "PENDING" state
- Tasks not being processed
- Worker logs show connection errors
- Frontend not updating from pending to completed

## Quick Fixes

### 1. Check Worker Status

```bash
docker ps | grep worker
docker logs infra-health-worker
```

### 2. Verify Environment Variables

Ensure `.env` file exists with correct MongoDB URL:

```env
MONGO_URL=mongodb://mongo:27017
```

### 3. Restart Worker Service

```bash
docker-compose restart worker
# Or full restart
docker-compose down
docker-compose up --build
```

### 4. Check Task Registration

Verify tasks are properly discovered in `celery_app.py`:

```python
celery_app.autodiscover_tasks(['app.tasks'])
```

## Debugging Steps

### 1. Check Worker Logs

```bash
docker logs infra-health-worker -f
```

Look for:

- Connection errors to MongoDB
- Task registration messages
- "Ready to work" messages

### 2. Test Task Manually

```bash
docker exec -it infra-health-worker python -c "
from app.tasks import run_health_check
result = run_health_check.delay('test-job-id')
print(f'Task ID: {result.id}')
"
```

### 3. Verify MongoDB Connection

```bash
docker exec -it infra-health-worker python -c "
import os
from pymongo import MongoClient
MONGO_URL = os.getenv('MONGO_URL', 'mongodb://localhost:27017')
client = MongoClient(MONGO_URL)
print('Connected to MongoDB:', client.server_info())
"
```

### 4. Check Celery Configuration

In `docker-compose.yml` ensure:

```yaml
worker:
  build: ./backend
  command: celery -A app.celery_app worker --loglevel=info
  env_file:
    - .env
  depends_on:
    mongo:
      condition: service_healthy
```

## Common Issues & Solutions

### Issue: Worker can't connect to MongoDB

**Solution**: Use `mongodb://mongo:27017` instead of `localhost`

### Issue: Tasks not found

**Solution**: Add `celery_app.autodiscover_tasks(['app.tasks'])` to `celery_app.py`

### Issue: Worker exits immediately

**Solution**: Check that MongoDB is healthy and accessible

### Issue: Jobs stuck in PENDING

**Solution**: Verify worker is running and can connect to both MongoDB and Redis/RabbitMQ
