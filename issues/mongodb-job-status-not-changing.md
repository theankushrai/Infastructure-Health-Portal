# MongoDB Job Status Not Changing

## Problem

- Job is created with `status = PENDING` ✅
- Celery task runs (sleep happens) ✅
- Status does NOT change to RUNNING/COMPLETED ❌

## Root Cause

**Mixing string IDs and MongoDB ObjectId.**

### The Issue

In FastAPI:

```python
result = jobs.insert_one(job)
job_id = str(result.inserted_id)   # 👈 string
```

In Celery task:

```python
jobs.update_one(
    {"_id": job_id},   # 👈 WRONG TYPE - string instead of ObjectId
    {"$set": {"status": "RUNNING"}}
)
```

MongoDB stores `_id` as `ObjectId("64f9...")`, but the query uses `{"_id": "64f9..."}` (string).

**Result:** Query matches 0 documents silently.

## Solution

### Fix tasks.py

```python
import time
from datetime import datetime
from bson import ObjectId
from pymongo import MongoClient
from app.celery_app import celery_app

client = MongoClient("mongodb://mongo:27017")  # Use service name in Docker
db = client["infra_health"]
jobs = db["jobs"]

@celery_app.task(bind=True)
def run_health_check(self, job_id: str):
    oid = ObjectId(job_id)  # ✅ Convert string to ObjectId

    # Mark job as running
    jobs.update_one(
        {"_id": oid},
        {"$set": {"status": "RUNNING"}}
    )

    time.sleep(10)

    # Mark job as completed
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

### Restart Celery Worker

Celery does not auto-reload code changes:

```bash
# Stop worker (Ctrl+C)
# Start again
celery -A app.celery_app worker --loglevel=info
```

### Test

```bash
curl -X POST "http://localhost:8000/jobs?app_id=APP-1"
```

Expected timeline:
| Time | Status |
| ----------- | --------- |
| immediately | PENDING |
| ~1 sec | RUNNING |
| ~10 sec | COMPLETED |

## Key Points

- **MongoDB `_id` is NOT a string**
- **Convert IDs explicitly at process boundaries**
- **MongoDB updates fail silently with wrong ID types**
- **Restart Celery worker after code changes**

## Debugging Tips

Add logging to verify:

```python
@celery_app.task(bind=True)
def run_health_check(self, job_id: str):
    oid = ObjectId(job_id)

    # Check if document exists
    doc = jobs.find_one({"_id": oid})
    print(f"Found document: {doc}")

    # Check update result
    result = jobs.update_one({"_id": oid}, {"$set": {"status": "RUNNING"}})
    print(f"Updated {result.modified_count} documents")
```

## Interview Answer

> "I hit a real-world issue where Celery tasks were running but MongoDB updates weren't happening because ObjectIds were being passed as strings across process boundaries. Fixing it required explicitly converting IDs inside the worker."
