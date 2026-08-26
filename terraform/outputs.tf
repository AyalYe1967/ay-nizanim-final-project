output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  value = module.vpc.private_app_subnet_ids
}

output "db_subnet_ids" {
  value = module.vpc.db_subnet_ids
}

output "db_subnet_group_name" {
  value = module.vpc.db_subnet_group_name
}

output "elasticache_subnet_group_name" {
  value = module.vpc.elasticache_subnet_group_name
}

output "alb_security_group_id" {
  value = module.vpc.alb_security_group_id
}

output "ecs_web_security_group_id" {
  value = module.vpc.ecs_web_security_group_id
}

output "ecs_worker_security_group_id" {
  value = module.vpc.ecs_worker_security_group_id
}

output "rds_security_group_id" {
  value = module.vpc.rds_security_group_id
}

output "redis_security_group_id" {
  value = module.vpc.redis_security_group_id
}

output "monitoring_security_group_id" {
  value = module.vpc.monitoring_security_group_id
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_repository_arn" {
  value = module.ecr.repository_arn
}

output "ecr_repository_name" {
  value = module.ecr.repository_name
}

output "rds_db_endpoint" {
  value = module.rds.db_endpoint
}

output "rds_db_address" {
  value = module.rds.db_address
}

output "rds_secret_arn" {
  value = module.rds.secret_arn
}

output "redis_endpoint" {
  value = module.elasticache.redis_endpoint
}

output "redis_port" {
  value = module.elasticache.redis_port
}

output "alb_dns_name" {
  value = module.alb.dns_name
}

output "alb_web_target_group_arn" {
  value = module.alb.web_target_group_arn
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  value = module.ecs.cluster_arn
}

output "ecs_execution_role_arn" {
  value = module.ecs.execution_role_arn
}

output "ecs_task_role_arn" {
  value = module.ecs.task_role_arn
}