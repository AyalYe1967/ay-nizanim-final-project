# =========================================================
# Django SECRET_KEY — Secrets Manager, same pattern as grafana_admin
# in monitoring.tf. Plain string secret (not JSON), so valueFrom in
# ecs.tf references the ARN directly with no ":key::" suffix.
# =========================================================
resource "random_password" "django_secret_key" {
  length  = 50
  special = true
}

resource "aws_secretsmanager_secret" "django_secret_key" {
  name                    = "ay-l-final-project-django-secret-key"
  recovery_window_in_days = 0 # lab/rebuild environment - not production

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "django_secret_key" {
  secret_id     = aws_secretsmanager_secret.django_secret_key.id
  secret_string = random_password.django_secret_key.result
}