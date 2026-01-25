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

build backend image = docker build -t infra-health-backend .
run backend image = docker run -p 8000:8000 infra-health-backend
docker compose with rebuild - docker-compose up --build
docker compose down - docker-compose down