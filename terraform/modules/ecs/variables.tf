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

variable "redis_port" {
  type    = number
  default = 6379
}

variable "tags" {
  type = map(string)
  default = {
    Owner     = "ayal"
    Project   = "final_project"
    ManagedBy = "terraform"
  }
}