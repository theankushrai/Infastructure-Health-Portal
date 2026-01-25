# MongoDB Connection Issues

## Common Symptoms

- "No address associated with hostname mongo" error
- Backend fails to connect to MongoDB
- Job status stuck in "PENDING" state

## Quick Fixes

### 1. Verify MongoDB Service

```bash
docker ps | grep mongo
docker logs infra-health-mongo
```

### 2. Check Connection String

Ensure `.env` has the correct MongoDB URL:

```env
MONGO_URL=mongodb://mongo:27017
```

### 3. Health Check Configuration

In `docker-compose.yml`:

```yaml
mongo:
  image: mongo:6
  healthcheck:
    test: ["CMD", "mongosh", "--eval", "db.runCommand('ping').ok"]
    interval: 5s
    timeout: 5s
    retries: 5
```

## Debugging Steps

1. Check MongoDB logs:

   ```bash
   docker logs infra-health-mongo
   ```

2. Test MongoDB connection:

   ```bash
   docker exec -it infra-health-mongo mongosh --eval "db.runCommand('ping')"
   ```

3. Verify database and collections:
   ```bash
   docker exec -it infra-health-mongo mongosh infra_health --eval "db.getCollectionNames()"
   ```
