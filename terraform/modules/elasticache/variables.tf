variable "elasticache_subnet_group_name" {
  description = "ElastiCache subnet group name from the VPC module"
  type        = string
}

variable "redis_security_group_id" {
  description = "Security group ID for Redis from the VPC module"
  type        = string
}

variable "node_type" {
  description = "ElastiCache node instance type"
  type        = string
  default     = "cache.t3.micro"
}

variable "engine_version" {
  description = "Valkey engine version"
  type        = string
  default     = "7.2"
}

variable "tags" {
  type = map(string)
  default = {
    Owner     = "ayal"
    Project   = "final_project"
    ManagedBy = "terraform"
  }
}