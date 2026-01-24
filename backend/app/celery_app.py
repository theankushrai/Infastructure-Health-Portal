from celery import Celery

celery_app = Celery(
    "infra_health",
    broker="mongodb://localhost:27017/infra_health",
    backend="mongodb://localhost:27017/infra_health",
)

celery_app.conf.update(
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
)

celery_app.autodiscover_tasks(["app"])
