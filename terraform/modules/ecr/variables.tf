variable "repository_names" {
  description = "Repo keys to create, prefixed automatically as ay-l-final-project-<key>"
  type        = list(string)
  default     = ["app", "prometheus", "grafana"]
}

variable "image_tag_mutability" {
  description = "IMMUTABLE or MUTABLE"
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "Enable automatic image scanning on push"
  type        = bool
  default     = true
}

variable "tags" {
  type = map(string)
  default = {
    Owner     = "ayal"
    Project   = "final_project"
    ManagedBy = "terraform"
  }
}