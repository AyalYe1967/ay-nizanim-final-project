output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  value = aws_subnet.private_app[*].id
}

output "db_subnet_ids" {
  value = aws_subnet.db[*].id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.main.name
}

output "elasticache_subnet_group_name" {
  value = aws_elasticache_subnet_group.main.name
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.main[*].id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "ecs_web_security_group_id" {
  value = aws_security_group.ecs_web.id
}

output "ecs_worker_security_group_id" {
  value = aws_security_group.ecs_worker.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "redis_security_group_id" {
  value = aws_security_group.redis.id
}

output "monitoring_security_group_id" {
  value = aws_security_group.monitoring.id
}