data "aws_region" "current" {}

locals {
  status_page_environment = [
    { name = "REDIS_HOST", value = var.redis_endpoint },
    { name = "REDIS_PORT", value = tostring(var.redis_port) },
    { name = "ALLOWED_HOSTS", value = var.allowed_hosts },
    { name = "SITE_URL", value = var.site_url },
    { name = "DEBUG", value = tostring(var.debug) },
    { name = "AWS_STORAGE_BUCKET_NAME", value = var.static_files_bucket_name },
    { name = "AWS_S3_REGION_NAME", value = data.aws_region.current.region },
    { name = "AWS_CLOUDFRONT_DOMAIN", value = var.static_files_cloudfront_domain },
  ]

  status_page_secrets = [
    { name = "SECRET_KEY", valueFrom = aws_secretsmanager_secret.django_secret_key.arn },
    { name = "POSTGRES_HOST", valueFrom = "${var.db_secret_arn}:host::" },
    { name = "POSTGRES_PORT", valueFrom = "${var.db_secret_arn}:port::" },
    { name = "POSTGRES_DB", valueFrom = "${var.db_secret_arn}:dbname::" },
    { name = "POSTGRES_USER", valueFrom = "${var.db_secret_arn}:username::" },
    { name = "POSTGRES_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" },
  ]
}

# --- Cluster ---
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# --- Service Connect namespace: internal DNS for ECS-to-ECS communication ---
# Replaces the file_sd_config + external discovery tool from the original
# EC2-based Master Plan (section 3.2) - Fargate tasks get stable internal DNS
# names (web, worker, scheduler, prometheus) that Prometheus scrapes directly.
resource "aws_service_discovery_http_namespace" "internal" {
  name        = "ay-l-final-project.internal"
  description = "Service Connect namespace for ECS-to-ECS communication (web, worker, scheduler, prometheus)"
  tags        = var.tags
}

# --- CloudWatch Log Groups (one per service, per master plan 5.1) ---
resource "aws_cloudwatch_log_group" "web" {
  name              = "/ecs/ay-l-final-project/web"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/ay-l-final-project/worker"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "scheduler" {
  name              = "/ecs/ay-l-final-project/scheduler"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# =========================================================
# Web — behind the ALB, container-level HEALTHCHECK on /ping/
# Registered on Service Connect as "web" so Prometheus can scrape
# /metrics internally without going through the ALB.
# =========================================================
resource "aws_ecs_task_definition" "web" {
  family                   = "ay-l-final-project-web"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.web_cpu
  memory                   = var.web_memory
  execution_role_arn       = local.execution_role_arn
  task_role_arn            = local.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "web"
      image = "${var.ecr_repository_url}:${var.image_tag}"
      portMappings = [{
        name          = "web"
        containerPort = var.container_port
        protocol      = "tcp"
      }]
      environment = local.status_page_environment
      secrets     = local.status_page_secrets
      healthCheck = {
        command     = ["CMD-SHELL", "python -c \"import sys, urllib.request; sys.exit(0 if urllib.request.urlopen('http://localhost:${var.container_port}/ping/').status == 200 else 1)\""]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.web.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "web"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "web" {
  name            = "ay-l-final-project-web"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = var.web_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_web_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.web_target_group_arn
    container_name   = "web"
    container_port   = var.container_port
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.internal.arn

    service {
      port_name      = "web"
      discovery_name = "web"

      client_alias {
        port     = var.container_port
        dns_name = "web"
      }
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = 30

  tags = var.tags
}

# =========================================================
# Worker — RQ background jobs, no ALB
# rq-exporter sidecar exposes /metrics on rq_exporter_port,
# registered on Service Connect as "worker" for Prometheus scraping.
# =========================================================
resource "aws_ecs_task_definition" "worker" {
  family                   = "ay-l-final-project-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.worker_cpu
  memory                   = var.worker_memory
  execution_role_arn       = local.execution_role_arn
  task_role_arn            = local.task_role_arn

  container_definitions = jsonencode([
    {
      name        = "worker"
      image       = "${var.ecr_repository_url}:${var.image_tag}"
      command     = ["python", "manage.py", "rqworker", "high", "default", "low"]
      environment = local.status_page_environment
      secrets     = local.status_page_secrets
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.worker.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "worker"
        }
      }
    },
    {
      name      = "rq-exporter"
      image     = "mdawar/rq-exporter:v3.1.0"
      essential = false
      portMappings = [{
        name          = "worker-metrics"
        containerPort = var.rq_exporter_port
        protocol      = "tcp"
      }]
      environment = [
        { name = "RQ_REDIS_URL", value = "redis://${var.redis_endpoint}:${var.redis_port}/0" },
        { name = "RQ_EXPORTER_PORT", value = tostring(var.rq_exporter_port) }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.worker.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "rq-exporter"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "worker" {
  name            = "ay-l-final-project-worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.worker_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_worker_security_group_id]
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.internal.arn

    service {
      port_name      = "worker-metrics"
      discovery_name = "worker"

      client_alias {
        port     = var.rq_exporter_port
        dns_name = "worker"
      }
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = var.tags
}

# =========================================================
# Scheduler — cron-style tasks, no ALB, desired_count = 1
# Same rq-exporter sidecar pattern as worker, registered as "scheduler".
# =========================================================
resource "aws_ecs_task_definition" "scheduler" {
  family                   = "ay-l-final-project-scheduler"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.scheduler_cpu
  memory                   = var.scheduler_memory
  execution_role_arn       = local.execution_role_arn
  task_role_arn            = local.task_role_arn

  container_definitions = jsonencode([
    {
      name        = "scheduler"
      image       = "${var.ecr_repository_url}:${var.image_tag}"
      command     = ["python", "manage.py", "rqscheduler"]
      environment = local.status_page_environment
      secrets     = local.status_page_secrets
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.scheduler.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "scheduler"
        }
      }
    },
    {
      name      = "rq-exporter"
      image     = "mdawar/rq-exporter:v3.1.0"
      essential = false
      portMappings = [{
        name          = "scheduler-metrics"
        containerPort = var.rq_exporter_port
        protocol      = "tcp"
      }]
      environment = [
        { name = "RQ_REDIS_URL", value = "redis://${var.redis_endpoint}:${var.redis_port}/0" },
        { name = "RQ_EXPORTER_PORT", value = tostring(var.rq_exporter_port) }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.scheduler.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "rq-exporter"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "scheduler" {
  name            = "ay-l-final-project-scheduler"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.scheduler.arn
  desired_count   = var.scheduler_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets = var.private_subnet_ids
    # Intentionally shared with the worker service - scheduler and worker have
    # identical network requirements (no public exposure, same rq-exporter
    # port, same RDS/Redis access). Not a copy-paste bug.
    security_groups  = [var.ecs_worker_security_group_id]
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.internal.arn

    service {
      port_name      = "scheduler-metrics"
      discovery_name = "scheduler"

      client_alias {
        port     = var.rq_exporter_port
        dns_name = "scheduler"
      }
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = var.tags
}
