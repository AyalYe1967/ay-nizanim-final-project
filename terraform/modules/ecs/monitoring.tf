# =========================================================
# Grafana admin credentials — Secrets Manager, same pattern as RDS
# =========================================================
resource "random_password" "grafana_admin" {
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret" "grafana_admin" {
  name                    = "ay-l-final-project-grafana-admin"
  recovery_window_in_days = 0 # lab/rebuild environment - not production

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "grafana_admin" {
  secret_id = aws_secretsmanager_secret.grafana_admin.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.grafana_admin.result
  })
}

# --- CloudWatch Log Groups ---
resource "aws_cloudwatch_log_group" "prometheus" {
  name              = "/ecs/ay-l-final-project/prometheus"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/ay-l-final-project/grafana"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# =========================================================
# Prometheus — no ALB, scrapes web/worker/scheduler via Service
# Connect internal DNS (web:8000, worker:8888, scheduler:8888).
# Scrape config is baked into the custom image at build time
# (Master Plan section 1.1 - wrapping the official image).
# Registered on Service Connect as "prometheus" so Grafana can
# reach it as a datasource without going through any ALB.
# =========================================================
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "ay-l-final-project-prometheus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.prometheus_cpu
  memory                   = var.prometheus_memory
  execution_role_arn       = local.execution_role_arn
  task_role_arn            = local.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "prometheus"
      image = "${var.prometheus_ecr_repository_url}:${var.prometheus_image_tag}"
      portMappings = [{
        name          = "prometheus"
        containerPort = var.prometheus_port
        protocol      = "tcp"
      }]
      environment = [
        { name = "AMP_REMOTE_WRITE_URL", value = var.amp_remote_write_url }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:${var.prometheus_port}/-/healthy || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.prometheus.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "prometheus"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "prometheus" {
  name            = "ay-l-final-project-prometheus"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = var.prometheus_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_monitoring_security_group_id]
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.internal.arn

    service {
      port_name      = "prometheus"
      discovery_name = "prometheus"

      client_alias {
        port     = var.prometheus_port
        dns_name = "prometheus"
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
# Grafana — behind its own dedicated ALB (alb_grafana module).
# Datasource auto-provisioned to Prometheus at http://prometheus:9090
# via Service Connect (baked into the custom image at build time).
# =========================================================
resource "aws_ecs_task_definition" "grafana" {
  family                   = "ay-l-final-project-grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.grafana_cpu
  memory                   = var.grafana_memory
  execution_role_arn       = local.execution_role_arn
  task_role_arn            = local.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "grafana"
      image = "${var.grafana_ecr_repository_url}:${var.grafana_image_tag}"
      portMappings = [{
        name          = "grafana"
        containerPort = var.grafana_port
        protocol      = "tcp"
      }]
      environment = [
        { name = "GF_SERVER_HTTP_PORT", value = tostring(var.grafana_port) },
        { name = "PROMETHEUS_URL", value = "http://prometheus:${var.prometheus_port}" },
        { name = "AMP_QUERY_URL", value = var.amp_query_url }
      ]
      secrets = [
        { name = "GF_SECURITY_ADMIN_USER", valueFrom = "${aws_secretsmanager_secret.grafana_admin.arn}:username::" },
        { name = "GF_SECURITY_ADMIN_PASSWORD", valueFrom = "${aws_secretsmanager_secret.grafana_admin.arn}:password::" },
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.grafana_port}/api/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 15
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.grafana.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "grafana"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "grafana" {
  name            = "ay-l-final-project-grafana"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = var.grafana_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_monitoring_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.grafana_target_group_arn
    container_name   = "grafana"
    container_port   = var.grafana_port
  }

  # Client-only Service Connect: no "service" block (Grafana isn't reached
  # via internal DNS, only via its ALB) - but enabling this injects the Envoy
  # sidecar needed for Grafana to resolve "prometheus" via the internal
  # namespace when calling PROMETHEUS_URL.
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.internal.arn
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = 30

  tags = var.tags
}
