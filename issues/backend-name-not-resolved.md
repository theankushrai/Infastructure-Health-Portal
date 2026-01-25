# Backend Name Not Resolved

## Problem

Frontend cannot connect to backend with error:

```
POST http://backend:8000/jobs?app_id=banana net::ERR_NAME_NOT_RESOLVED
```

## Root Cause

The browser cannot resolve the Kubernetes service name `backend` because:

- Browser runs on your laptop (outside Kubernetes)
- `backend` DNS only exists inside the cluster
- JavaScript executes in the browser, not in the pod

## Solution Options

### Option 1: Kubernetes Ingress (Recommended)

Create a single entry point that routes traffic to appropriate services.

#### Install Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl get pods -n ingress-nginx
```

#### Create Ingress YAML

Create `k8s/ingress/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: infra-health-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
    - host: infra-health.local
      http:
        paths:
          - path: /api(/|$)(.*)
            pathType: Prefix
            backend:
              service:
                name: backend
                port:
                  number: 8000
          - path: /(.*)
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80
```

#### Apply Ingress

```bash
kubectl apply -f k8s/ingress/ingress.yaml
kubectl get ingress
```

#### Add Host Entry

Add to your hosts file (`C:\Windows\System32\drivers\etc\hosts` on Windows):

```
127.0.0.1 infra-health.local
```

#### Update Frontend API Calls

Change frontend to use relative paths:

```javascript
fetch("/api/jobs?app_id=banana");
```

#### Test

Access the app at `http://infra-health.local`

### Option 2: Port Forwarding (Development Only)

Forward backend service to local port:

```bash
kubectl port-forward svc/backend 8000:8000 &
```

Update frontend to use `http://localhost:8000`

## Key Points

- **Browser code runs outside Kubernetes**, even if frontend container runs inside
- **Service DNS only works within the cluster**
- **Ingress provides production-ready routing** and solves CORS issues
- **Port forwarding is for development only**

## Interview Answer

> "We use Kubernetes Ingress as a single entry point. The frontend is served at `/` and API requests under `/api` are routed to the backend service. This avoids exposing internal service DNS to the browser and removes CORS issues."
