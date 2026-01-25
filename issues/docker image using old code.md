# Docker Image Using Old Code

## Problem

Kubernetes deployments are running with outdated Docker images after code changes.

## Solution

### Build and Load New Image

```bash
docker build --no-cache -t infra-health-backend:latest backend
```

### Load Image into Kind Cluster

```bash
kind load docker-image infra-health-backend:latest --name infra-health
```

### Restart Deployments

```bash
kubectl rollout restart deployment/backend
kubectl rollout restart deployment/worker
```

## Notes

- `--no-cache` ensures fresh build without layer caching
- Restart deployments to force them to use the new image
- Verify with `kubectl get pods` to see new pods starting
