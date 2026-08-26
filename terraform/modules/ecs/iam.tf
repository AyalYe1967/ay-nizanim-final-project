# --- Trust policy: both roles are assumed by ECS tasks ---
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

# =========================================================
# Task Execution Role
# Pulls the image from ECR + writes logs to CloudWatch.
# Used by ECS itself to start the task - never by app code.
# =========================================================
resource "aws_iam_role" "execution" {
  name               = "ay-l-final-project-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# =========================================================
# Task Role
# Runtime permissions for the application itself (Django/RQ).
# Also used by the RunTask calls for collectstatic and migrate.
# =========================================================
resource "aws_iam_role" "task" {
  name               = "ay-l-final-project-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "task_permissions" {
  statement {
    sid     = "SecretsManagerReadDbCredentials"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }

  dynamic "statement" {
    for_each = var.static_files_bucket_arn != null ? [1] : []
    content {
      sid    = "S3StaticAndMediaFiles"
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
      ]
      resources = ["${var.static_files_bucket_arn}/*"]
    }
  }

  dynamic "statement" {
    for_each = var.static_files_bucket_arn != null ? [1] : []
    content {
      sid       = "S3ListBucket"
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = [var.static_files_bucket_arn]
    }
  }
}

resource "aws_iam_role_policy" "task_permissions" {
  name   = "ay-l-final-project-ecs-task-policy"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_permissions.json
}