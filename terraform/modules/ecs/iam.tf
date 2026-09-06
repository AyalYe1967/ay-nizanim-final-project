# ECS can either use roles created here (personal accounts) or roles supplied
# by the environment (restricted school accounts). External roles are never
# created, attached to, or otherwise modified by this module.

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  count = var.create_iam_roles ? 1 : 0

  name               = "${lower(var.project_name)}-${var.environment}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_base" {
  count = var.create_iam_roles ? 1 : 0

  role       = aws_iam_role.execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution_secrets" {
  statement {
    sid     = "ReadTaskSecrets"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      var.db_secret_arn,
      aws_secretsmanager_secret.django_secret_key.arn,
      aws_secretsmanager_secret.django_admin.arn,
      aws_secretsmanager_secret.grafana_admin.arn,
    ]
  }
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = var.create_iam_roles ? 1 : 0

  name   = "${lower(var.project_name)}-${var.environment}-ecs-read-secrets"
  role   = aws_iam_role.execution[0].id
  policy = data.aws_iam_policy_document.execution_secrets.json
}

resource "aws_iam_role" "task" {
  count = var.create_iam_roles ? 1 : 0

  name               = "${lower(var.project_name)}-${var.environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "task_access" {
  statement {
    sid       = "ListStaticMediaBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.static_files_bucket_arn]
  }

  statement {
    sid    = "ManageStaticMediaObjects"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${var.static_files_bucket_arn}/*"]
  }

  statement {
    sid    = "UseManagedPrometheus"
    effect = "Allow"
    actions = [
      "aps:GetLabels",
      "aps:GetMetricMetadata",
      "aps:GetSeries",
      "aps:QueryMetrics",
      "aps:RemoteWrite",
    ]
    resources = [var.amp_workspace_arn]
  }

  statement {
    sid    = "ReadCloudWatchMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "ec2:DescribeTags",
      "tag:GetResources",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "task_access" {
  count = var.create_iam_roles ? 1 : 0

  name   = "${lower(var.project_name)}-${var.environment}-ecs-application-access"
  role   = aws_iam_role.task[0].id
  policy = data.aws_iam_policy_document.task_access.json
}

locals {
  execution_role_arn = var.create_iam_roles ? aws_iam_role.execution[0].arn : var.external_execution_role_arn
  task_role_arn      = var.create_iam_roles ? aws_iam_role.task[0].arn : var.external_task_role_arn
}
