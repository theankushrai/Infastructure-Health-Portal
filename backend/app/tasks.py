import time

from bson import ObjectId
from app.celery_app import celery_app
from pymongo import MongoClient
from datetime import datetime, timezone

client = MongoClient("mongodb://localhost:27017")
db = client["infra_health"]
jobs = db["jobs"]


@celery_app.task()
def run_health_check(job_id: str):

    oid = ObjectId(job_id)
    # mark job as running
    jobs.update_one({"_id": oid}, {"$set": {"status": "RUNNING"}})

    # fake work
    time.sleep(10)

    # mark job as completed
    jobs.update_one(
        {"_id": oid},
        {"$set": {"status": "COMPLETED", "completed_at": datetime.now(timezone.utc)}},
    )

    return "done"
