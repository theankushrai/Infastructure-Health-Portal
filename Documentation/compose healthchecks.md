# Docker Compose Healthchecks

Love this question — **healthchecks are one of those “senior-level” Docker things** that silently save you from chaos later 😄
Let’s go **line by line**, and I’ll also explain **why this matters in real systems** (backend → Mongo dependency).

---

## 🧪 Healthcheck Configuration Example

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

Think of this as Docker asking MongoDB:

> “Hey… are you _actually_ ready, or just running?”

---

## 🧠 Why healthchecks exist (VERY important)

Without healthcheck:

- Container = **running**
- MongoDB might still be:
  - Starting up
  - Initializing storage
  - Not ready to accept connections

With healthcheck:

- Docker knows the difference between:
  - 🟡 _Process running_
  - 🟢 _Service healthy_

This is **critical** when:

- Backend depends on Mongo
- You use `depends_on`
- You move to Kubernetes later

---

## 🔍 Line-by-line Breakdown

---

### 1️⃣ `test`

```yaml
test: ["CMD", "mongosh", "--eval", "db.runCommand('ping').ok"]
```

This is the **actual check command**.

Docker runs this **inside the container**.

### Breakdown:

- `CMD` → run as a normal shell command
- `mongosh` → MongoDB shell client
- `--eval` → run a one-liner command
- `db.runCommand('ping').ok` → MongoDB ping

### What does this return?

- `1` → MongoDB is healthy ✅
- Error / non-zero → MongoDB is unhealthy ❌

So Docker is literally doing:

```bash
mongosh --eval "db.runCommand('ping').ok"
```

If Mongo responds → 👍
If Mongo is dead/hung → 👎

---

### 2️⃣ `interval: 5s`

```yaml
interval: 5s
```

- Docker runs the healthcheck **every 5 seconds**
- Good for fast feedback in local dev

In prod, you might increase this to reduce noise.

---

### 3️⃣ `timeout: 5s`

```yaml
timeout: 5s
```

- If Mongo doesn’t respond within **5 seconds**
- Healthcheck = **failed attempt**

Prevents Docker from waiting forever.

---

### 4️⃣ `retries: 5`

```yaml
retries: 5
```

- Docker allows **5 consecutive failures**
- After that → container marked **unhealthy**

So total grace time ≈

```
5 retries × 5 seconds = ~25 seconds
```

---

## 📊 Container States You’ll See

Run:

```bash
docker ps
```

You’ll see:

```
STATUS
Up 30 seconds (healthy)
```

Or:

```
Up 30 seconds (unhealthy)
```

This is **gold for debugging**.

---

## 🔗 How Backend Uses This (Real Value)

### Without healthcheck

Backend might start → Mongo not ready → ❌ crash

### With healthcheck

You can do:

```yaml
depends_on:
  mongo:
    condition: service_healthy
```

Now:

- Backend starts **only after Mongo is ready**
- No race conditions 🎯

---

## 🧠 Mental Model (Super Important)

```
Container Running ≠ Service Ready
```

Healthcheck bridges this gap.

---

## ⚠️ Common Mistakes

### ❌ Checking only process existence

```yaml
test: ["CMD", "ps", "aux"]
```

This only checks if Mongo process exists — **not if it works**.

### ✅ Checking real functionality (what you did)

```yaml
db.runCommand('ping')
```

This is the **correct** way.

---

## 🔑 TL;DR (Plain English)

This healthcheck says:

> “Every 5 seconds, try to ping MongoDB.
> If it responds within 5 seconds, mark it healthy.
> If it fails 5 times in a row, mark it unhealthy.”

---

## 🧠 Why this matters for _your_ project

Given your **infra-health platform**:

- Healthchecks = core concept
- You’re already thinking like production
- This maps **1:1 to Kubernetes readiness probes**

---
