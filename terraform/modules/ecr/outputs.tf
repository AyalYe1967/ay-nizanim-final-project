output "repository_urls" {
  description = "Map of repo key (app/prometheus/grafana) to repository URL"
  value       = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}

output "repository_arns" {
  description = "Map of repo key to repository ARN"
  value       = { for k, r in aws_ecr_repository.this : k => r.arn }
}

output "repository_names" {
  description = "Map of repo key to full repository name"
  value       = { for k, r in aws_ecr_repository.this : k => r.name }
}