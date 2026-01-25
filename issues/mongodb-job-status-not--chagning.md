Good catch — this is a **classic, important bug**, and fixing it will teach you a LOT 👍
Nothing is “wrong” conceptually. This is a **MongoDB + Celery gotcha**.

Let’s debug this **calmly, step by step** 🧘‍♂️

---

# ❌ Problem (What’s happening)

- Job is created → `status = PENDING` ✅
- Celery task runs (sleep happens) ✅
- Status **does NOT change to RUNNING / COMPLETED** ❌

That means:
👉 **The Celery task is running, but the MongoDB update query is not matching any document**

---

# 🔍 Root Cause (VERY IMPORTANT)

### You are mixing **string IDs** and **MongoDB ObjectId**

Let’s look carefully.

### In FastAPI:

```python
result = jobs.insert_one(job)
job_id = str(result.inserted_id)   # 👈 string
```

### In Celery task:

```python
jobs.update_one(
    {"_id": job_id},   # 👈 WRONG TYPE
    {"$set": {"status": "RUNNING"}}
)
```

But MongoDB stores `_id` as:

```python
ObjectId("64f9...")
```

So this query:

```python
{"_id": "64f9..."}   ❌
```

**matches nothing**, silently.

MongoDB does NOT throw an error.
It just updates **0 documents**.

---

# ✅ Fix (Simple & Correct)

You must convert the string back to `ObjectId` **inside the worker**.

---

## 🛠 STEP 1: Fix `tasks.py`

Open `app/tasks.py` and update it like this 👇

```python
import time
from datetime import datetime
from bson import ObjectId
from pymongo import MongoClient
from app.celery_app import celery_app

client = MongoClient("mongodb://localhost:27017")
db = client["infra_health"]
jobs = db["jobs"]

@celery_app.task(bind=True)
def run_health_check(self, job_id: str):
    oid = ObjectId(job_id)  # ✅ FIX

    # mark job as running
    jobs.update_one(
        {"_id": oid},
        {"$set": {"status": "RUNNING"}}
    )

    time.sleep(10)

    # mark job as completed
    jobs.update_one(
        {"_id": oid},
        {
            "$set": {
                "status": "COMPLETED",
                "completed_at": datetime.utcnow()
            }
        }
    )

    return "done"
```

---

## 🛠 STEP 2: Restart Celery Worker (IMPORTANT)

Celery **does not auto-reload code**.

Stop worker:

```
CTRL + C
```

Start again:

```bash
celery -A app.celery_app worker --loglevel=info
```

---

## 🛠 STEP 3: Test Again

Call API:

```bash
curl -X POST "http://127.0.0.1:8000/jobs?app_id=APP-1"
```

Now observe MongoDB:

| Time        | Status    |
| ----------- | --------- |
| immediately | PENDING   |
| ~1 sec      | RUNNING   |
| ~10 sec     | COMPLETED |

🎉 **THIS SHOULD NOW WORK**

---

# 🧠 Why this bug is GOLD for interviews

You can literally say this:

> “I hit a real-world issue where Celery tasks were running but MongoDB updates weren’t happening because ObjectIds were being passed as strings across process boundaries. Fixing it required explicitly converting IDs inside the worker.”

This shows:

- Debugging skill
- Distributed thinking
- MongoDB understanding

Huge plus.

---

# 🧠 Rule to remember forever

> **MongoDB `_id` is NOT a string.
> Convert it explicitly in every process boundary.**

This will save you hours in future.

---
