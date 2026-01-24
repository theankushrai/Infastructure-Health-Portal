import os
from celery import Celery

MONGO_URL = os.getenv("MONGO_URL", "mongodb://localhost:27017")

celery_app = Celery(
    "infra_health",
    broker=f"{MONGO_URL}/infra_health",
    backend=f"{MONGO_URL}/infra_health",
)

celery_app.conf.update(
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
)
# autodiscover tasks
celery_app.autodiscover_tasks(["app.tasks"])
