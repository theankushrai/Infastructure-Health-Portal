It feels great to have the cluster finally talking to itself properly! This was a classic "Kubernetes Path-Matching" puzzle. Here is a summary of the issue and the solution, formatted for you to save as a post-mortem or documentation.

---

# 📝 Troubleshooting Report: Infrastructure Health Portal 404 Issue

## 1. The Problem

Requests from the frontend to `http://infra-health.local/api/jobs` were returning **404 Not Found**.

Even though the backend pods were healthy and accessible via `kubectl port-forward`, the **NGINX Ingress Controller** was rejecting the traffic.

## 2. Root Causes Identified

### A. The "Host" Mismatch

The Ingress was configured with `host: infra-health.local`. However, when accessing the site via `localhost` or an IP address, NGINX did not recognize the "Host" header. It ignored our custom rules and sent the traffic to the **default-backend**, which always returns a 404.

### B. Path "Double-Prefixing"

The backend code (FastAPI) was using `APIRouter(prefix="/api")`, and the Ingress was also looking for `/api`. This created a "Path War" where NGINX and FastAPI were either doubling the prefix or stripping too much of it away.

### C. Ingress Rewrite Conflicts

The use of `rewrite-target: /` was stripping the `/api` portion before it reached the backend. Since the backend code was explicitly looking for routes starting with `/api`, it couldn't find the modified paths.

---

## 3. The Solutions Applied

### ✅ Fix 1: Catch-All Ingress (Removed Host Restriction)

We removed the `host` requirement from the Ingress rules. This allowed NGINX to process `/api` and `/` requests regardless of whether the user typed `localhost`, an IP, or a domain name.

### ✅ Fix 2: Aligned Pathing

We removed the `rewrite-target` annotation. We kept the `/api` prefix in **both** the Ingress and the FastAPI code. This ensured that the URL the frontend sends is exactly what the backend expects to receive.

### ✅ Fix 3: YAML Indentation & Service Connection

We verified that the Ingress `backend.service.name` matched the `metadata.name` of the Service, and that the Service `selector` matched the Deployment `labels`.

---

## 4. Final Configuration State

### Ingress (`ingress.yaml`)

```yaml
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: backend
                port:
                  number: 8000
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80

```

### Backend (`main.py`)

```python
router = APIRouter(prefix="/api")

@router.get("/health")
def health_check():
    return {"status": "ok"}

app.include_router(router)

```

### Frontend (`App.js`)

```javascript
const API_BASE_URL = '/api'; // Relative path works perfectly through Ingress;

```

---

## 5. Lessons Learned

* **Trust the Logs:** The NGINX logs showing `[upstream-default-backend]` were the key to realizing the `host` header was the problem.
* **Simple is Better:** Avoiding `rewrite-target` annotations makes the pathing logic much easier to follow;
* **Endpoints Matter:** Always check `kubectl get endpoints` to ensure the Service actually "sees" the Pods.

**Now that the communication is fixed, would you like me to help you set up a more robust MongoDB connection string or handle the CORS settings properly so you can stop using "*" in production;?**