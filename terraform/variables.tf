variable "project_name" {
  description = "Prefix used for naming and tagging all resources (naming convention: ay-l-final-project-<service>)"
  type        = string
  default     = "ay-l-final-project"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to deploy subnets into (exactly 2)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (ALB, NAT Gateway) - one per AZ"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private app subnets (ECS Fargate tasks) - one per AZ"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for isolated DB subnets (RDS, ElastiCache) - one per AZ"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "single_nat_gateway" {
  description = "If true, deploy a single shared NAT Gateway instead of one per AZ"
  type        = bool
  default     = false
}

variable "container_port" {
  description = "Port the Django app listens on inside the ECS task"
  type        = number
  default     = 8000
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for the ALB HTTPS listener. Leave null until a domain exists - ALB serves HTTP only until then"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    "Owner" = "ayal"
  }
}

variable "image_tag" {
  description = "Immutable Git commit SHA tag for the application image"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{7,40}$", var.image_tag))
    error_message = "image_tag must be a 7-40 character hexadecimal Git commit SHA."
  }
}

variable "prometheus_image_tag" {
  description = "Immutable Git commit SHA tag for the Prometheus image"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{7,40}$", var.prometheus_image_tag))
    error_message = "prometheus_image_tag must be a 7-40 character hexadecimal Git commit SHA."
  }
}

variable "grafana_image_tag" {
  description = "Immutable Git commit SHA tag for the Grafana image"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{7,40}$", var.grafana_image_tag))
    error_message = "grafana_image_tag must be a 7-40 character hexadecimal Git commit SHA."
  }
}

variable "create_iam_roles" {
  description = "Create ECS execution/task IAM roles. Set false when an environment supplies pre-created roles."
  type        = bool
  default     = true
}

variable "external_execution_role_arn" {
  description = "Pre-created ECS execution role ARN used when create_iam_roles is false"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.create_iam_roles || (
      var.external_execution_role_arn != null &&
      can(regex("^arn:[^:]+:iam::[0-9]{12}:role/.+$", var.external_execution_role_arn))
    )
    error_message = "external_execution_role_arn must be a valid IAM role ARN when create_iam_roles is false."
  }
}

variable "external_task_role_arn" {
  description = "Pre-created ECS application task role ARN used when create_iam_roles is false"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.create_iam_roles || (
      var.external_task_role_arn != null &&
      can(regex("^arn:[^:]+:iam::[0-9]{12}:role/.+$", var.external_task_role_arn))
    )
    error_message = "external_task_role_arn must be a valid IAM role ARN when create_iam_roles is false."
  }
}
