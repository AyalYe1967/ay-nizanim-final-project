output "cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "Used by the GitHub Actions pipeline to target ecs update-service / run-task"
  value       = aws_ecs_cluster.main.arn
}

output "execution_role_arn" {
  description = "Reused by future RunTask definitions (collectstatic, migrate) that need the same ECR pull + Logs permissions"
  value       = var.execution_role_arn
}

output "task_role_arn" {
  description = "Reused by future RunTask definitions that need the same runtime permissions (e.g. migrate needs DB access)"
  value       = var.task_role_arn
}

output "web_service_name" {
  value = aws_ecs_service.web.name
}

output "worker_service_name" {
  value = aws_ecs_service.worker.name
}

output "scheduler_service_name" {
  value = aws_ecs_service.scheduler.name
}

output "prometheus_service_name" {
  value = aws_ecs_service.prometheus.name
}

output "grafana_service_name" {
  value = aws_ecs_service.grafana.name
}

output "service_connect_namespace_arn" {
  description = "ARN of the Service Connect namespace - reusable by future services needing internal DNS"
  value       = aws_service_discovery_http_namespace.internal.arn
}

output "grafana_admin_secret_arn" {
  description = "Secrets Manager ARN holding the Grafana admin username/password"
  value       = aws_secretsmanager_secret.grafana_admin.arn
}