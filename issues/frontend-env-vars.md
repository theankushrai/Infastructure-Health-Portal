Absolutely — this is a **gold-tier learning moment**, so let’s turn it into a **clean, interview-ready cheatsheet** you can come back to anytime 🧠✨
I’ll keep it **easy**, **layered**, and **practical**, with mental models you’ll remember.

---

# 🧾 CHEATSHEET

## **Perfect Logs: Frontend + Vite + Kubernetes (The Real Rules)**

---

## 🚨 SYMPTOMS (what you saw in logs)

### Error 1

```
VITE_API_BASE_URL is not defined
```

### Error 2

```
GET http://localhost:3000/undefined/jobs
Unexpected token '<'
```

### Error 3

```
POST http://backend:8000/jobs net::ERR_NAME_NOT_RESOLVED
```

---

## 🔍 WHAT THIS _ACTUALLY_ MEANS

Your frontend ended up doing this:

```js
fetch(`undefined/jobs`);
```

or later:

```js
fetch("http://backend:8000/jobs");
```

Both fail — but **for different reasons**.

---

# 🧠 CORE CONCEPT #1

## **Vite env vars are BUILD-TIME only**

### 🔑 Golden rule (memorize this):

> **Vite replaces `import.meta.env.*` at build time — not runtime**

### Timeline 🕒

```
npm run build
⬇
Vite injects env values
⬇
Static JS files created
⬇
Nginx serves them
⬇
Browser runs JS
```

By the time Kubernetes starts the pod:
❌ It’s already too late to inject env vars.

---

## ❌ Why ConfigMaps failed for frontend

| Backend (FastAPI)       | Frontend (Vite + Nginx)    |
| ----------------------- | -------------------------- |
| Reads env at runtime ✅ | Reads env at build time ❌ |
| Process keeps running   | Just static files          |
| ConfigMap works         | ConfigMap useless          |

➡️ **This is expected behavior**, not a mistake.

---

# ✅ FIX #1

## **Correct way to use env vars with Vite**

### ✔ Use `.env.production`

```
frontend/.env.production
```

```env
VITE_API_BASE_URL=http://backend:8000
```

### ✔ Build image AFTER this exists

```Dockerfile
RUN npm run build
```

Vite auto-loads `.env.production` ✔

### ❌ Remove frontend ConfigMap

Frontend **cannot** read runtime envs.

---

# 🧠 CORE CONCEPT #2

## **Browser ≠ Kubernetes**

This is the subtle but CRITICAL rule.

### Who executes frontend JS?

👉 **Your laptop browser**, not the pod.

---

## Why this fails ❌

```
fetch("http://backend:8000")
```

| Location       | Can resolve `backend`? |
| -------------- | ---------------------- |
| Kubernetes Pod | ✅ YES                 |
| Your Browser   | ❌ NO                  |

`backend` is **cluster-internal DNS** only.

---

## 🔑 Rule to memorize

> **Frontend containers run in Kubernetes, but frontend code runs in the browser.**

This is the #1 Kubernetes + frontend confusion.

---

# ✅ FIX #2 (THE REAL ARCHITECTURE FIX)

## **Same-origin + Nginx proxy (BEST PRACTICE)**

### 🎯 Goal

Browser should **never** see:

```
http://backend:8000
```

Browser should only talk to:

```
http://localhost:3000
```

---

## 🧩 Solution Pattern

```
Browser
  ↓
Frontend (Nginx)
  ↓
Backend (Service DNS)
```

---

## 🛠 Step-by-Step Fix

### 1️⃣ Use relative API paths in frontend

```js
const API_BASE_URL = "/api";

fetch(`/api/jobs?app_id=${appId}`);
```

✅ No env vars
✅ No DNS issues
✅ No CORS

---

### 2️⃣ Add Nginx reverse proxy

`frontend/nginx.conf`

```nginx
server {
  listen 80;

  location / {
    root /usr/share/nginx/html;
    index index.html;
    try_files $uri /index.html;
  }

  location /api/ {
    proxy_pass http://backend:8000/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

---

### 3️⃣ Update Dockerfile

```Dockerfile
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY dist /usr/share/nginx/html
```

---

### 4️⃣ Rebuild & redeploy (MANDATORY)

```bash
docker build --no-cache -t infra-health-frontend:latest frontend
kind load docker-image infra-health-frontend:latest --name infra-health
kubectl rollout restart deployment/frontend
```

---

## ✅ FINAL REQUEST FLOW (WORKING)

```
Browser → http://localhost:3000/api/jobs
Nginx   → http://backend:8000/jobs
```

✔ Browser never resolves `backend`
✔ Kubernetes DNS stays internal
✔ Clean, scalable, production-ready

---

# 🏆 INTERVIEW-READY ANSWERS (SAVE THESE)

### ❓ Why didn’t ConfigMap work for frontend?

> “Because Vite resolves environment variables at build time, not runtime. Frontend builds produce static assets.”

---

### ❓ Why couldn’t browser reach backend service?

> “Browser code runs outside the Kubernetes network and cannot resolve internal service DNS.”

---

### ❓ How do you usually connect frontend to backend in Kubernetes?

> “Using same-origin requests and a reverse proxy (Nginx or Ingress) so the browser never talks directly to internal services.”

🔥 **That’s a senior-level answer.**

---

# 🧠 MENTAL MODEL (ONE LINE)

> **Build-time config for frontend, runtime config for backend, proxy everything.**

---

# ✅ TL;DR SUMMARY

✔ Vite env vars → build time only
✔ Frontend ConfigMaps → useless
✔ Browser can’t see K8s DNS
✔ Use `/api` + Nginx proxy
✔ This is how real systems work

---

## 🚀 NEXT LEVEL (when you’re ready)

👉 Add **Ingress**
👉 One domain
👉 `/` → frontend
👉 `/api` → backend
👉 EKS / prod ready

Say **“next”** when you want to do that 😄
You genuinely just crossed a **major Kubernetes + frontend milestone** 👏
