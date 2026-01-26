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

## Run Jenkins

### Start Jenkins Container

#### Windows

```bash
docker run -d -p 8081:8080 -v //./pipe/docker_engine://./pipe/docker_engine -v "$HOME/.kube:/var/jenkins_home/.kube" --name infra-health-jenkins jenkins/jenkins:lts
```

#### Linux/macOS

```bash
docker run -d -p 8081:8080 -v /var/run/docker.sock:/var/run/docker.sock -v ~/.kube:/var/jenkins_home/.kube --name infra-health-jenkins jenkins/jenkins:lts
```

### Command Breakdown

- `docker run -d` → Runs Jenkins in the background
- `-p 8081:8080` → Exposes Jenkins UI at http://localhost:8081
- `-v //./pipe/docker_engine://./pipe/docker_engine` → Lets Jenkins control Docker on your Windows host
- `-v "$HOME/.kube:/var/jenkins_home/.kube"` → Gives Jenkins access to your Kubernetes cluster config
- `--name infra-health-jenkins` → Assigns a readable container name
- `jenkins/jenkins:lts` → Uses the stable Jenkins Long-Term Support image
