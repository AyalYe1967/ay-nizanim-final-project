variable "db_subnet_group_name" {
  description = "DB subnet group name from the VPC module"
  type        = string
}

variable "rds_security_group_id" {
  description = "Security group ID for RDS from the VPC module"
  type        = string
}

variable "db_name" {
  description = "Name of the initial PostgreSQL database"
  type        = string
  default     = "statuspage"
}

variable "db_username" {
  description = "Master username for PostgreSQL"
  type        = string
  default     = "statuspage"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16"
}

variable "tags" {
  type = map(string)
  default = {
    Owner     = "ayal"
    Project   = "final_project"
    ManagedBy = "terraform"
  }
}
