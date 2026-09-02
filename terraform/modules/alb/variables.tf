variable "vpc_id" {
  description = "VPC ID where the ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB (must span at least 2 AZs)"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB, created in the VPC module"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener. Leave null until a domain exists - ALB will serve HTTP only until then"
  type        = string
  default     = null
}

variable "health_check_path" {
  description = "Health check path for the target group - liveness endpoint (/ping/), not the deep readiness check (/health/)"
  type        = string
  default     = "/ping/"
}

variable "target_port" {
  description = "Port the Django web container listens on"
  type        = number
  default     = 8000
}

variable "tags" {
  type = map(string)
  default = {
    Owner     = "ayal"
    Project   = "final_project"
    ManagedBy = "terraform"
  }
}