output "repository_url" {
  description = "URL of the ECR repository (used for docker push/pull and ECS task definitions)"
  value       = aws_ecr_repository.status_page.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository (used for IAM policy scoping)"
  value       = aws_ecr_repository.status_page.arn
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.status_page.name
}