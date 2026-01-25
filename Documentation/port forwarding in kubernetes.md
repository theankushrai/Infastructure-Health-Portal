# Port Forwarding in Kubernetes

## Basic Port Forwarding

Forward local port 3000 to frontend service port 80:

```bash
kubectl port-forward svc/frontend 3000:80
```

## Common Use Cases

### Access Backend API

```bash
kubectl port-forward svc/backend 8000:8000
```

### Access MongoDB

```bash
kubectl port-forward svc/mongo 27017:27017
```

### Access Specific Pod

```bash
kubectl port-forward pod/frontend-pod-name 3000:80
```

## Options

- `-n <namespace>`: Specify namespace
- `--address 0.0.0.0`: Allow external connections
- `--context <context>`: Use specific kubeconfig context

## Example with Options

```bash
kubectl port-forward svc/frontend 3000:80 -n infra-health --address 0.0.0.0
```

## Notes

- Port forwarding is temporary (stops when command ends)
- Useful for local development and debugging
- Only works while kubectl command is running
