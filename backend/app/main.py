from fastapi import FastAPI, HTTPException
from pymongo import DESCENDING, MongoClient
from datetime import datetime, timezone
from app.tasks import run_health_check
from bson import ObjectId, objectid
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = MongoClient("mongodb://mongo:27017")
db = client["infra_health"]
jobs = db["jobs"]  # this is a mongo collection


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


@app.get("/jobs")
def get_all_jobs(app_id: str):
    jobs_cursor = jobs.find({"application_id": app_id}).sort(
        "created_at", direction=DESCENDING
    )
    result = []
    for job in jobs_cursor:
        result.append(
            {
                "job_id": str(job["_id"]),
                "application_id": job["application_id"],
                "status": job["status"],
                "created_at": job["created_at"],
                "completed_at": job.get("completed_at"),
            }
        )
    return result
