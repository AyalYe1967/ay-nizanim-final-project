variable "project_name" {
  description = "Prefix used for naming and tagging all resources (naming convention: AY-L-FINAL-PROJECT-<service>)"
  type        = string
  default     = "AY-L-FINAL-PROJECT"
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

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    "Owner" = "ayal",
    "project" = "final_project"
  }
}