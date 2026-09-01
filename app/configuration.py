import os


# Required settings from the assignment's configuration_example.py

ALLOWED_HOSTS = [
    host.strip()
    for host in os.getenv("ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")
    if host.strip()
]

DATABASE = {
    "NAME": os.getenv("POSTGRES_DB", "statuspage"),
    "USER": os.getenv("POSTGRES_USER", "statuspage"),
    "PASSWORD": os.environ["POSTGRES_PASSWORD"],
    # In Docker this is the Compose service name, not localhost.
    "HOST": os.getenv("POSTGRES_HOST", "postgres"),
    "PORT": os.getenv("POSTGRES_PORT", "5432"),
    "CONN_MAX_AGE": 300,
}

REDIS = {
    "tasks": {
        # Redis database 0 is used for background-task queues.
        "HOST": os.getenv("REDIS_HOST", "redis"),
        "PORT": int(os.getenv("REDIS_PORT", "6379")),
        "PASSWORD": "",
        "DATABASE": 0,
        "SSL": False,
    },
    "caching": {
        # Redis database 1 is used for caching.
        "HOST": os.getenv("REDIS_HOST", "redis"),
        "PORT": int(os.getenv("REDIS_PORT", "6379")),
        "PASSWORD": "",
        "DATABASE": 1,
        "SSL": False,
    },
}

# S3 static/media storage (django-storages).
# Left unset (None) during local dev and during `docker build`'s collectstatic
# step (Master Plan 1.1) - settings.py falls back to local filesystem storage
# whenever AWS_STORAGE_BUCKET_NAME is empty, so no AWS credentials are needed
# at build time. Only the ECS runtime containers and the dedicated
# collectstatic RunTask (Master Plan 4.6) set this env var.
AWS_STORAGE_BUCKET_NAME = os.getenv("AWS_STORAGE_BUCKET_NAME", "")
AWS_S3_REGION_NAME = os.getenv("AWS_S3_REGION_NAME", "us-east-1")

SITE_URL = os.getenv("SITE_URL", "http://localhost:8000")

SECRET_KEY = os.environ["SECRET_KEY"]


# Optional setting: enabled only for our local test environment.
DEBUG = os.getenv("DEBUG", "False").lower() in ("1", "true", "yes", "on")

TIME_ZONE = "UTC"