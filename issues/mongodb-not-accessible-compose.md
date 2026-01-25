
## 🧠 What this error REALLY means (simple words)

Error:

```
No address associated with hostname mongo
```

Translation 👇

> “When the backend container tried to talk to `mongo`, Docker had **not yet made the `mongo` service reachable**.”

This happens because:

* `depends_on` ❌ does **NOT** mean “Mongo is ready”
* It only means “Mongo container was started”
* MongoDB needs a few seconds before it can accept connections
* Your backend tries to connect **too early**
* DNS exists, but Mongo is not ready → connection fails → backend crashes

This is **extremely common**. Even senior engineers hit this.

---

## ✅ The CORRECT fix (industry standard)

### 👉 Add a **MongoDB healthcheck**

### 👉 Make backend wait until Mongo is healthy

This is the **right solution**, not hacks or sleeps.

---

# 🍼 Fix Step 1: Add healthcheck to MongoDB

Open `docker-compose.yml`
Update the `mongo` service like this 👇

```yaml
services:
  mongo:
    image: mongo:6
    container_name: infra-health-mongo
    ports:
      - "27017:27017"
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.runCommand('ping').ok"]
      interval: 5s
      timeout: 5s
      retries: 5
```

🧠 What this does:

* Docker keeps checking: “Is Mongo actually ready?”
* Only marks it **healthy** when it responds

---

# 🍼 Fix Step 2: Make backend wait for Mongo

Update your backend service:

```yaml
  backend:
    build: ./backend
    container_name: infra-health-backend
    ports:
      - "8000:8000"
    depends_on:
      mongo:
        condition: service_healthy
```

👉 Now:

* Backend will start **only after Mongo is ready**
* DNS + connection both work

---

## 🚨 IMPORTANT: Remove old containers

Docker sometimes keeps broken containers around.

Run this **once**:

```bash
docker-compose down
docker-compose up --build
```

---

## ✅ What should happen now

You should see logs like:

```
mongo    | Waiting for connections
mongo    | ... healthy
backend  | Uvicorn running on http://0.0.0.0:8000
```

Then test:

* [http://localhost:8000/health](http://localhost:8000/health)
* POST `/jobs`

🎉 Backend should stay UP.

---

## 🧠 Interview gold (store this)

If asked:

> “How do you handle service dependencies in Docker?”

You say:

> “I use healthchecks and conditional `depends_on` to ensure services only start when their dependencies are actually ready.”

That is a **senior-level answer**.

---

## ⚠️ What NOT to do (important)

❌ Don’t add `time.sleep(10)` in code
❌ Don’t retry infinitely without control
❌ Don’t blame DNS

You fixed it the **right way**.

