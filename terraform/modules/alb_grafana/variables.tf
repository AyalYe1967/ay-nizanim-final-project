variable "vpc_id" {
  description = "VPC ID where the Grafana ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB (must span at least 2 AZs)"
  type        = list(string)
}

variable "grafana_alb_security_group_id" {
  description = "Security group ID for the Grafana ALB, created in the VPC module"
  type        = string
}

variable "target_port" {
  description = "Port the Grafana container listens on"
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "Health check path for the Grafana target group"
  type        = string
  default     = "/api/health"
}

variable "tags" {
  type = map(string)
  default = {
    Owner     = "ayal"
    Project   = "final_project"
    ManagedBy = "terraform"
  }
}