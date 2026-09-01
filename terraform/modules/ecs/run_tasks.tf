# =========================================================
# RunTask definitions (Master Plan 4.6, 4.7) - NOT services.
# These are invoked on-demand from the CI/CD pipeline via
# `aws ecs run-task`, one-shot, then exit. The pipeline is
# responsible for `ecs wait tasks-stopped` + checking the exit
# code (4.7) before proceeding to Deploy.
#
# Both reuse the same image, execution_role_arn and task_role_arn
# as the web/worker/scheduler services - no new IAM roles needed.
# =========================================================

resource "aws_cloudwatch_log_group" "migrate" {
  name              = "/ecs/ay-l-final-project/migrate"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "collectstatic" {
  name              = "/ecs/ay-l-final-project/collectstatic"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# --- Database Migration (4.7) ---
# python manage.py migrate --noinput. Async run-task - the pipeline must
# `aws ecs wait tasks-stopped` and check exitCode == 0 itself; Terraform
# only defines the task shape.
resource "aws_ecs_task_definition" "migrate" {
  family                   = "ay-l-final-project-migrate"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.migrate_cpu
  memory                   = var.migrate_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn             = var.task_role_arn

  container_definitions = jsonencode([
    {
      name    = "migrate"
      image   = "${var.ecr_repository_url}:${var.image_tag}"
      command = ["python", "manage.py", "migrate", "--noinput"]
      environment = [
        { name = "REDIS_HOST", value = var.redis_endpoint },
        { name = "REDIS_PORT", value = tostring(var.redis_port) }
      ]
      secrets = [
        { name = "SECRET_KEY", valueFrom = aws_secretsmanager_secret.django_secret_key.arn },
        { name = "POSTGRES_HOST", valueFrom = "${var.db_secret_arn}:host::" },
        { name = "POSTGRES_PORT", valueFrom = "${var.db_secret_arn}:port::" },
        { name = "POSTGRES_DB", valueFrom = "${var.db_secret_arn}:dbname::" },
        { name = "POSTGRES_USER", valueFrom = "${var.db_secret_arn}:username::" },
        { name = "POSTGRES_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.migrate.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "migrate"
        }
      }
    }
  ])

  tags = var.tags
}

# --- Static Files Upload (4.6) ---
# python manage.py collectstatic --noinput, this time WITH
# AWS_STORAGE_BUCKET_NAME set, so settings.py picks the S3ManifestStaticStorage
# backend and actually uploads hashed static files to S3 (the `docker build`
# collectstatic pass in the Dockerfile stays local-only, per 1.1/1.2).
resource "aws_ecs_task_definition" "collectstatic" {
  family                   = "ay-l-final-project-collectstatic"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.collectstatic_cpu
  memory                   = var.collectstatic_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn             = var.task_role_arn

  container_definitions = jsonencode([
    {
      name    = "collectstatic"
      image   = "${var.ecr_repository_url}:${var.image_tag}"
      command = ["python", "manage.py", "collectstatic", "--noinput"]
      environment = [
        { name = "REDIS_HOST", value = var.redis_endpoint },
        { name = "REDIS_PORT", value = tostring(var.redis_port) },
        { name = "AWS_STORAGE_BUCKET_NAME", value = var.static_files_bucket_name },
        { name = "AWS_S3_REGION_NAME", value = data.aws_region.current.region },
        { name = "AWS_CLOUDFRONT_DOMAIN", value = var.static_files_cloudfront_domain }
      ]
      secrets = [
        { name = "SECRET_KEY", valueFrom = aws_secretsmanager_secret.django_secret_key.arn },
        { name = "POSTGRES_HOST", valueFrom = "${var.db_secret_arn}:host::" },
        { name = "POSTGRES_PORT", valueFrom = "${var.db_secret_arn}:port::" },
        { name = "POSTGRES_DB", valueFrom = "${var.db_secret_arn}:dbname::" },
        { name = "POSTGRES_USER", valueFrom = "${var.db_secret_arn}:username::" },
        { name = "POSTGRES_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.collectstatic.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "collectstatic"
        }
      }
    }
  ])

  tags = var.tags
}