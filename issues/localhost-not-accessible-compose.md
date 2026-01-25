# 🍼 DOCKER COMPOSE — BABY STEP 2

## Add Backend API service

---

## 🧠 One VERY important concept (read first)

Inside Docker Compose:

- ❌ `localhost` does NOT work between containers
- ✅ Containers talk using **service names**

So:

```
mongodb://localhost:27017 ❌
mongodb://mongo:27017     ✅
```

We will fix this properly.

---

## STEP 1️⃣ Update Mongo connection in backend code

Open:

```
backend/app/main.py
backend/app/tasks.py
```

Wherever you have:

```python
MongoClient("mongodb://localhost:27017")
```

👉 Replace with:

```python
MongoClient("mongodb://mongo:27017")
```

Why?

- `mongo` is the **service name** in docker-compose
- Docker provides DNS automatically

⚠️ This change is **required** for Docker/Kubernetes.

---

## STEP 2️⃣ Update Celery Mongo URLs

In:

```
backend/app/celery_app.py
```

Change:

```python
broker="mongodb://localhost:27017/infra_health",
backend="mongodb://localhost:27017/infra_health",
```

👉 To:

```python
broker="mongodb://mongo:27017/infra_health",
backend="mongodb://mongo:27017/infra_health",
```