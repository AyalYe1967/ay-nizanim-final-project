resource "aws_elasticache_replication_group" "status_page" {
  replication_group_id = "ay-l-final-project-redis"
  description          = "Valkey cache/queue backend for status-page"

  engine         = "valkey"
  engine_version = var.engine_version
  node_type      = var.node_type
  port           = 6379

  num_cache_clusters         = 1
  automatic_failover_enabled = false

  subnet_group_name  = var.elasticache_subnet_group_name
  security_group_ids = [var.redis_security_group_id]

  apply_immediately = true

  tags = var.tags
}