# Frontend Environment Variables Resolved at Build Time

## Problem

Frontend shows error:

```
VITE_API_BASE_URL is not defined
GET http://localhost:3000/undefined/jobs?app_id=banana
```

## Root Cause

**Vite environment variables are resolved at BUILD TIME, not runtime.**

When you build the frontend:

- JavaScript is compiled and environment variables are replaced
- `import.meta.env.VITE_API_BASE_URL` becomes a literal string
- Kubernetes ConfigMaps are too late - the JS is already built

## Why Backend ConfigMaps Don't Work for Frontend

| Component               | When env vars are read |
| ----------------------- | ---------------------- |
| Backend (FastAPI)       | Runtime ✅             |
| Frontend (Vite + Nginx) | Build time ❌          |

## Solution Options

### Option 1: Build with API URL Baked In (Recommended)

#### Create Production Environment File

Create `frontend/.env.production`:

```env
VITE_API_BASE_URL=http://backend:8000
```

#### Ensure Dockerfile Uses Production Build

Your Dockerfile should include:

```dockerfile
RUN npm run build
```

Vite automatically loads `.env.production` during build.

#### Remove Frontend ConfigMap

Delete or ignore `k8s/frontend/configmap.yaml` - frontend doesn't read runtime envs.

#### Rebuild and Redeploy

```bash
docker build --no-cache -t infra-health-frontend:latest frontend
kind load docker-image infra-health-frontend:latest --name infra-health
kubectl rollout restart deployment/frontend
```

#### Test

```bash
kubectl port-forward svc/frontend 3000:80
```

Access at `http://localhost:3000`

### Option 2: Runtime Configuration (Advanced)

Create a config endpoint that returns runtime configuration:

```javascript
// Fetch config at runtime
fetch("/config.json")
  .then((response) => response.json())
  .then((config) => {
    // Use config.API_BASE_URL
  });
```

## Key Points

- **Frontend env vars ≠ Backend env vars**
- **Build-time vs runtime configuration**
- **Static files can't read Kubernetes ConfigMaps**
- **Use environment-specific `.env` files for different deployments**

## Interview Answer

> "Since the frontend is a static Vite build served by Nginx, environment variables are resolved at build time. We bake backend service URLs into the build using environment-specific `.env` files."

## Production Considerations

For different environments:

- `.env.development` - local development
- `.env.staging` - staging environment
- `.env.production` - production environment

Build with:

```bash
npm run build  # Uses .env.production by default
```
