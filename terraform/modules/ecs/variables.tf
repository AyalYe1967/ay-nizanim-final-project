variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "Private app subnet IDs for the ECS tasks (awsvpc networking)"
  type        = list(string)
}

variable "ecs_web_security_group_id" {
  description = "Security group ID for the web service, created in the VPC module"
  type        = string
}

variable "ecs_worker_security_group_id" {
  description = "Security group ID for the worker and scheduler services, created in the VPC module"
  type        = string
}

variable "cluster_name" {
  type    = string
  default = "ay-l-final-project-cluster"
}

variable "ecr_repository_url" {
  description = "ECR repository URL - image source for all three services"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy (git SHA / build number from the CI/CD pipeline)"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port the Django web container listens on"
  type        = number
  default     = 8000
}

variable "web_target_group_arn" {
  description = "ALB target group ARN for the web service"
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN for RDS credentials - scopes the Task Role policy and used as a container secret"
  type        = string
}

variable "redis_endpoint" {
  description = "Valkey primary endpoint, passed as a container env var"
  type        = string
}

variable "web_desired_count" {
  type    = number
  default = 1
}

variable "worker_desired_count" {
  type    = number
  default = 1
}

variable "scheduler_desired_count" {
  description = "Must stay at 1 - a scheduler with more than one running instance duplicates cron jobs"
  type        = number
  default     = 1
}

variable "web_cpu" {
  type    = number
  default = 256
}

variable "web_memory" {
  type    = number
  default = 512
}

variable "worker_cpu" {
  type    = number
  default = 256
}

variable "worker_memory" {
  type    = number
  default = 512
}

variable "scheduler_cpu" {
  type    = number
  default = 256
}

variable "scheduler_memory" {
  type    = number
  default = 512
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "static_files_bucket_arn" {
  description = "S3 bucket ARN for static/media files. Leave null until the S3 module exists - the S3 permissions statement is skipped until then"
  type        = string
  default     = null
}

variable "static_files_bucket_name" {
  description = "S3 bucket name (not ARN) for static/media files - passed to web/worker/scheduler as AWS_STORAGE_BUCKET_NAME so django-storages picks up the S3 backend (settings.py falls back to local storage when empty)"
  type        = string
  default     = ""
}

variable "redis_port" {
  type    = number
  default = 6379
}

variable "execution_role_arn" {
  description = "ARN of the pre-existing ECS Task Execution Role (managed manually, not by Terraform)"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the pre-existing ECS Task Role (managed manually, not by Terraform)"
  type        = string
}

# =========================================================
# Prometheus + Grafana (monitoring services)
# =========================================================
variable "prometheus_ecr_repository_url" {
  description = "ECR repository URL for the Prometheus image"
  type        = string
}

variable "grafana_ecr_repository_url" {
  description = "ECR repository URL for the Grafana image"
  type        = string
}

variable "prometheus_image_tag" {
  type    = string
  default = "latest"
}

variable "grafana_image_tag" {
  type    = string
  default = "latest"
}

variable "ecs_monitoring_security_group_id" {
  description = "Security group ID for Prometheus and Grafana tasks, created in the VPC module"
  type        = string
}

variable "grafana_target_group_arn" {
  description = "ALB target group ARN for the Grafana service (from the alb_grafana module)"
  type        = string
}

variable "prometheus_port" {
  type    = number
  default = 9090
}

variable "grafana_port" {
  type    = number
  default = 3000
}

variable "rq_exporter_port" {
  description = "Port the rq-exporter sidecar listens on, for worker/scheduler metrics"
  type        = number
  default     = 8888
}

variable "prometheus_desired_count" {
  type    = number
  default = 1
}

variable "grafana_desired_count" {
  type    = number
  default = 1
}

variable "prometheus_cpu" {
  type    = number
  default = 256
}

variable "prometheus_memory" {
  type    = number
  default = 512
}

variable "grafana_cpu" {
  type    = number
  default = 256
}

variable "grafana_memory" {
  type    = number
  default = 512
}

variable "amp_remote_write_url" {
  description = "AMP remote_write endpoint URL, from the amp module"
  type        = string
}

variable "amp_query_url" {
  description = "AMP query endpoint URL, from the amp module"
  type        = string
}

variable "tags" {
  type = map(string)
  default = {
    Owner     = "ayal"
    Project   = "final_project"
    ManagedBy = "terraform"
  }
}


# =========================================================
# RunTask definitions (migrate, collectstatic - Master Plan 4.6/4.7)
# =========================================================
variable "migrate_cpu" {
  type    = number
  default = 256
}

variable "migrate_memory" {
  type    = number
  default = 512
}

variable "collectstatic_cpu" {
  type    = number
  default = 256
}

variable "collectstatic_memory" {
  type    = number
  default = 512
}
