output "db_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = aws_db_instance.status_page.endpoint
}

output "db_address" {
  description = "RDS hostname only, without port"
  value       = aws_db_instance.status_page.address
}

output "db_port" {
  value = aws_db_instance.status_page.port
}

output "db_instance_id" {
  value = aws_db_instance.status_page.identifier
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials - used to scope the ECS Task Role IAM policy"
  value       = aws_secretsmanager_secret.db_credentials.arn
}