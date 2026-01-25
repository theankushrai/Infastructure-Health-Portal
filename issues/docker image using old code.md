docker build --no-cache -t infra-health-backend:latest backend
kind load docker-image infra-health-backend:latest --name infra-health
kubectl rollout restart deployment/backend
kubectl rollout restart deployment/worker
