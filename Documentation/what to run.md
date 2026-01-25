# Development Commands

## Start Celery Worker

```bash
python -m celery -A app.celery_app worker --loglevel=info --pool=solo
```

## Run FastAPI Server

```bash
fastapi dev app/main.py
```

## Run MongoDB

```bash
docker run -d --name mongo -p 27017:27017 mongo
```

## Docker Commands

### Build Backend Image

```bash
docker build -t infra-health-backend .
```

### Run Backend Container

```bash
docker run -p 8000:8000 infra-health-backend
```

### Docker Compose

```bash
# Start with rebuild
docker-compose up --build

# Stop all services
docker-compose down
```

### Build Frontend for Kubernetes

```bash
docker build --build-arg VITE_API_BASE_URL=http://infra-health.local/api -t infra-health-frontend:k8s ./frontend
```
