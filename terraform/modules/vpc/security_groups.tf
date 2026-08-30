# ALB SG: open port 433,80
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow inbound HTTP/HTTPS from the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alb-sg"
  })
}

# ECS Web SG: open traffic from ALB

resource "aws_security_group" "ecs_web" {
  name        = "${var.project_name}-ecs-web-sg"
  description = "Allow inbound traffic from ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "From ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Metrics scrape from Prometheus"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_monitoring.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecs-web-sg"
  })
}

# ECS Worker/Scheduler SG:

resource "aws_security_group" "ecs_worker" {
  name        = "${var.project_name}-ecs-worker-sg"
  description = "No public exposure - worker/scheduler are not behind any load balancer. Prometheus scrapes metrics internally."
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Metrics scrape from Prometheus (rq-exporter sidecar)"
    from_port       = 8888
    to_port         = 8888
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_monitoring.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecs-worker-sg"
  })
}

# RDS SG: get traffic from ECS (web + worker + scheduler)

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow PostgreSQL traffic from ECS tasks only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from ECS web"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_web.id, aws_security_group.ecs_worker.id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rds-sg"
  })
}

# Redis SG: get traffic from ECS (web + worker + scheduler)

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Allow Redis traffic from ECS tasks only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis from ECS web"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_web.id, aws_security_group.ecs_worker.id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-redis-sg"
  })
}

# Grafana ALB SG: public entry point for the Grafana dashboard
# NOTE: 0.0.0.0/0 is a deliberate temporary choice - tighten to a specific
# CIDR (e.g. office/VPN IP) before treating this as production-grade.
resource "aws_security_group" "grafana_alb" {
  name        = "${var.project_name}-grafana-alb-sg"
  description = "Public entry point for Grafana - temporarily open, tighten before production"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Grafana UI (temporary - open to internet)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-grafana-alb-sg"
  })
}

<<<<<<< Updated upstream
# ECS Monitoring SG: Prometheus + Grafana Fargate tasks
# Grafana only reachable from its ALB. Prometheus has no public/ALB exposure -
# it is reached internally via ECS Service Connect.
=======
>>>>>>> Stashed changes
resource "aws_security_group" "ecs_monitoring" {
  name        = "${var.project_name}-ecs-monitoring-sg"
  description = "Prometheus and Grafana ECS tasks - Grafana ingress from its ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Grafana UI from Grafana ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana_alb.id]
  }

  ingress {
    description = "Prometheus query traffic from Grafana (self-referencing - both share this SG)"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ecs-monitoring-sg"
  })
}
