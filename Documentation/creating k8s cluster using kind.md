# Creating Kubernetes Cluster with Kind

## Prerequisites

Check if following tools are installed:

```bash
docker --version
kubectl version --client
kind version
```

## Cluster Setup

### Create cluster

```bash
kind create cluster --name infra-health
```

### Verify cluster is running

```bash
kubectl get nodes
kubectl get pods -A
```

### Create namespace

```bash
kubectl create namespace infra-health
kubectl config set-context --current --namespace=infra-health
```

## Deploy Services

### MongoDB

```bash
kubectl apply -f k8s/mongo/
kubectl get pods
kubectl get svc
```

### Backend

```bash
kind load docker-image infra-health-backend:latest --name infra-health
kubectl apply -f k8s/backend/
kubectl get pods
```

### Worker

```bash
kind load docker-image infra-health-backend:latest --name infra-health
kubectl apply -f k8s/worker/
kubectl get pods
```

### Frontend

```bash
docker build -t infra-health-frontend:latest frontend
kind load docker-image infra-health-frontend:latest --name infra-health
kubectl apply -f k8s/frontend/deployment.yaml
kubectl get pods
kubectl apply -f k8s/frontend/service.yaml
kubectl get svc
```

## Ingress Setup

### Install ingress controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl get pods -n ingress-nginx
```

### Apply ingress rules

```bash
kubectl apply -f k8s/ingress/ingress.yaml
```

## Local Access

### Add host entry

Edit your hosts file to resolve `infra-health.local`:

#### Windows

```
C:\Windows\System32\drivers\etc\hosts
```

Add this line:

```
127.0.0.1 infra-health.local
```

#### Linux/macOS

```bash
echo "127.0.0.1 infra-health.local" | sudo tee -a /etc/hosts
```
