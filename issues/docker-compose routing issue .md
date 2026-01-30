## Root Cause Analysis & Gateway Solution

This document outlines the debugging process and final infrastructure fix for the **Infrastructure Health Portal** local development environment.

---

### 🛑 The Problem: "Unexpected token <"

We were encountering a persistent `SyntaxError: Unexpected token '<', "<html>..." is not valid JSON` in the browser console whenever the frontend tried to fetch data.

#### The Technical Why:

1. **Port Mismatch:** The React frontend was running on **port 3000**, while the FastAPI backend was on **port 8000**.
2. **Relative Pathing:** The React code used a relative path: `const API_BASE_URL = '/api';`.
3. **The "Silent" 404:** When the browser requested `localhost:3000/api/jobs`, the Frontend Nginx server (on port 3000) looked for a folder named `/api` in its own static files. Finding nothing, it served the default `index.html` file (which starts with `<html>`).
4. **Parsing Failure:** The React app tried to parse this HTML string as JSON, saw the `<` character, and crashed.

---

### 🏗️ The Infrastructure Solution: The Gateway Pattern

Instead of changing the frontend code or modifying the Dockerfiles, we implemented a **Reverse Proxy Gateway**. This mimics a production Kubernetes Ingress or Load Balancer.

#### How it works:

We added a third service called `gateway` (using a lightweight Nginx image) that acts as the single entry point for the entire application.

* **Entry Point:** You now access the app via `http://localhost:8080`.
* **Routing Logic:**
* Any request starting with `/api/` is transparently forwarded to the **Backend (8000)**.
* All other requests are forwarded to the **Frontend (3000)**.



---

### 🛠️ The Implementation

#### 1. `docker-compose.yml` (Gateway Service)

We added the gateway and mapped it to **8080** to avoid conflicts with existing **Kind cluster** Ingress controllers on port 80.

```yaml
services:
  gateway:
    image: nginx:alpine
    container_name: infra-health-gateway
    ports:
      - "8080:80"
    volumes:
      - ./gateway.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - frontend
      - backend

```

#### 2. `gateway.conf` (The Router)

This configuration maps the traffic internally within the Docker network.

```nginx
server {
    listen 80;

    location /api/ {
        proxy_pass http://infra-health-backend:8000/api/;
        proxy_set_header Host $host;
    }

    location / {
        proxy_pass http://infra-health-frontend:80/;
        proxy_set_header Host $host;
    }
}

```

---

### ✅ Benefits of this Fix

* **Zero Code Changes:** No need to modify the React `App.js` or change environment variables;!
* **Zero Dockerfile Changes:** The frontend and backend Dockerfiles remain untouched;!
* **No CORS Issues:** Since the browser sees both HTML and API calls coming from the same origin (`localhost:8080`), CORS restrictions no longer apply;!
* **Production Parity:** This setup is functionally identical to how the app runs in the Jenkins/Kind cluster environment;!

---

**Would you like me to create a shell script that automates this clean-build and gateway-start process for you;?**