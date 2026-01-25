Perfect logs. This is a **very important frontend + Kubernetes + Vite lesson**, and you just hit it at the exact right time.

I’ll explain **what’s happening**, **why it’s happening**, and **the correct fix** (no hacks).

---

## ❌ What the error is REALLY saying

The first line is the key 👇

```
VITE_API_BASE_URL is not defined
```

Then everything else follows from that:

```
GET http://localhost:3000/undefined/jobs?app_id=banana
```

So your frontend is literally doing:

```js
fetch(`undefined/jobs?app_id=banana`);
```

Which becomes:

```
http://localhost:3000/undefined/jobs
```

That’s why:

- 404 errors
- HTML response instead of JSON
- `Unexpected token '<'`

---

## 🧠 ROOT CAUSE (this is the big concept)

### 👉 **Vite environment variables are resolved at BUILD TIME, not runtime**

This is the critical rule.

You are currently doing this:

- Building frontend image ❌ without `VITE_API_BASE_URL`
- Trying to inject it later via Kubernetes ConfigMap ❌

That **does not work with Vite**.

By the time Nginx serves the files:

- JavaScript is already compiled
- `import.meta.env.VITE_API_BASE_URL` is already replaced
- Kubernetes env vars are **too late**

---

## ❌ Why backend-style ConfigMap DOES NOT work for frontend

Backend (FastAPI):

- Reads env vars at runtime ✅

Frontend (Vite + Nginx):

- Reads env vars at build time ❌
- Static JS files, no Node process running

This is **expected behavior**, not your mistake.

---

## ✅ The CORRECT ways to fix this (2 options)

I’ll give you **both**, and tell you which one to use **now**.

---

# ✅ OPTION 1 (RECOMMENDED FOR YOU)

## Build frontend with API URL baked in

This is the **simplest, cleanest, interview-safe** approach for your project.

### 🧩 Step 1 — Add `.env.production` in frontend

Create:

```
frontend/.env.production
```

Put this inside:

```env
VITE_API_BASE_URL=http://backend:8000
```

---

### 🧩 Step 2 — Make sure Dockerfile uses production build

Your Dockerfile already does:

```Dockerfile
RUN npm run build
```

Vite automatically loads `.env.production` during build ✅

---

### 🧩 Step 3 — Remove frontend ConfigMap (important)

You **do NOT need** this anymore:

```
k8s/frontend/configmap.yaml
```

Frontend does **not** read runtime envs.

You can delete it or ignore it.

---

### 🧩 Step 4 — Rebuild & redeploy frontend (MANDATORY)

```bash
docker build --no-cache -t infra-health-frontend:latest frontend
kind load docker-image infra-health-frontend:latest --name infra-health
kubectl rollout restart deployment/frontend
```

---

### 🧩 Step 5 — Test again

```bash
kubectl port-forward svc/frontend 3000:80
```

Open:
👉 [http://localhost:3000](http://localhost:3000)

Now the browser should call:

```
http://backend:8000/jobs
```

🎉 **This will work**

---

## 🏆 Interview-ready explanation (VERY IMPORTANT)

If interviewer asks:

> “How do you handle environment variables in frontend on Kubernetes?”

You answer:

> “Since the frontend is a static Vite build served by Nginx, environment variables are resolved at build time. We bake backend service URLs into the build using environment-specific `.env` files.”

That answer is **excellent**.

---

## ✅ Why this bug is actually GOOD

You just learned a **core frontend deployment rule** that many backend engineers don’t know.

You now understand:

- Backend envs ≠ Frontend envs
- Build-time vs runtime config
- Why frontend ConfigMaps often don’t work

This is **real-world knowledge**.

---
