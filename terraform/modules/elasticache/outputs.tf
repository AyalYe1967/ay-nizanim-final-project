output "redis_endpoint" {
  description = "Valkey primary endpoint (host) - used as REDIS_URL in Django/RQ"
  value       = aws_elasticache_replication_group.status_page.primary_endpoint_address
}

output "redis_port" {
  value = aws_elasticache_replication_group.status_page.port
}

output "cluster_id" {
  value = aws_elasticache_replication_group.status_page.replication_group_id
}