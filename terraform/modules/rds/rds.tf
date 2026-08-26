resource "random_password" "db_password" {
  length  = 20
  special = false
}

resource "aws_db_instance" "status_page" {
  identifier     = "ay-l-final-project-rds"
  engine         = "postgres"
  engine_version = var.engine_version

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name  = var.db_subnet_group_name
  vpc_security_group_ids = [var.rds_security_group_id]

  multi_az = false 

  backup_retention_period = 1
  skip_final_snapshot     = true 
  deletion_protection     = false

  publicly_accessible = false 

  tags = var.tags
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "ay-l-final-project-rds-credentials"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    host     = aws_db_instance.status_page.address
    port     = aws_db_instance.status_page.port
    dbname   = var.db_name
  })
}