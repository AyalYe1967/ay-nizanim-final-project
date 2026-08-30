module "vpc" {
  source = "./modules/vpc"

  project_name              = var.project_name
  environment               = var.environment
  aws_region                = var.aws_region
  vpc_cidr                  = var.vpc_cidr
  availability_zones        = var.availability_zones
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_app_subnet_cidrs  = var.private_app_subnet_cidrs
  db_subnet_cidrs           = var.db_subnet_cidrs
  single_nat_gateway        = var.single_nat_gateway
  container_port            = var.container_port
  tags                      = var.tags
}

module "ecr" {
  source = "./modules/ecr"
}

module "rds" {
  source = "./modules/rds"

  db_subnet_group_name  = module.vpc.db_subnet_group_name
  rds_security_group_id = module.vpc.rds_security_group_id
}

module "elasticache" {
  source = "./modules/elasticache"

  elasticache_subnet_group_name = module.vpc.elasticache_subnet_group_name
  redis_security_group_id       = module.vpc.redis_security_group_id
}

module "alb" {
  source = "./modules/alb"

  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.vpc.alb_security_group_id
  certificate_arn       = var.acm_certificate_arn
}

module "ecs" {
  source = "./modules/ecs"

  vpc_id                            = module.vpc.vpc_id
  private_subnet_ids                = module.vpc.private_app_subnet_ids
  ecs_web_security_group_id         = module.vpc.ecs_web_security_group_id
  ecs_worker_security_group_id      = module.vpc.ecs_worker_security_group_id
  ecr_repository_url                = module.ecr.repository_urls["app"]
  web_target_group_arn              = module.alb.web_target_group_arn
  db_secret_arn                     = module.rds.secret_arn
  redis_endpoint                    = module.elasticache.redis_endpoint
  execution_role_arn                = "arn:aws:iam::992382545251:role/ay-l-final-project-ecs-execution-role-manual"
  task_role_arn                     = "arn:aws:iam::992382545251:role/ay-l-final-project-ecs-task-role-manual"
  prometheus_ecr_repository_url     = module.ecr.repository_urls["prometheus"]
  grafana_ecr_repository_url        = module.ecr.repository_urls["grafana"]
  ecs_monitoring_security_group_id  = module.vpc.ecs_monitoring_security_group_id
  grafana_target_group_arn          = module.alb_grafana.grafana_target_group_arn
}

module "s3" {
  source = "./modules/s3"

  bucket_name = "ay-l-final-project-static"
  tags        = var.tags
}

module "alb_grafana" {
  source = "./modules/alb_grafana"

  vpc_id                        = module.vpc.vpc_id
  public_subnet_ids             = module.vpc.public_subnet_ids
  grafana_alb_security_group_id = module.vpc.grafana_alb_security_group_id
}
<<<<<<< Updated upstream
=======

module "amp" {
  source = "./modules/amp"
}
>>>>>>> Stashed changes
