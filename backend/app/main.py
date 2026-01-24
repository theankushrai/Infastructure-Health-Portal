from fastapi import FastAPI, HTTPException
from pymongo import MongoClient
from datetime import datetime, timezone
from app.tasks import run_health_check
from bson import ObjectId, objectid


client = MongoClient("mongodb://localhost:27017/")
db = client["infra_health"]
jobs = db["jobs"]  # this is a mongo collection

app = FastAPI()


@app.get("/health")
def get_health():
    return {"status": "ok"}


@app.post("/jobs")
def create_job(app_id: str):
    job = {
        "application_id": app_id,
        "status": "PENDING",
        "created_at": datetime.now(timezone.utc),
    }

    result = jobs.insert_one(job)
    job_id = str(result.inserted_id)

    # trigger celery task
    run_health_check.delay(job_id)

    return {"job_id": job_id, "message": "Health check started"}


@app.get("/jobs/{job_id}")
def get_job(job_id: str):
    try:
        oid = ObjectId(job_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid job ID")

    job = jobs.find_one({"_id": oid})

    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    return {
        "job_id": str(job["_id"]),
        "application_id": job["application_id"],
        "status": job["status"],
        "created_at": job["created_at"],
        "completed_at": job.get("completed_at"),
    }
