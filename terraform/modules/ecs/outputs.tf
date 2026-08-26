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
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "Reused by future RunTask definitions that need the same runtime permissions (e.g. migrate needs DB access)"
  value       = aws_iam_role.task.arn
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