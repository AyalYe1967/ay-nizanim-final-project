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

# =========================================================
# Django admin bootstrap — one-time seed credentials for the
# idempotent `bootstrap_admin` management command (run as a
# RunTask step in the CD pipeline, right after `migrate`).
#
# JSON secret (unlike django_secret_key above, which is a plain
# string) so valueFrom in run_tasks.tf uses ":key::" suffixes,
# same convention as the DB credentials secret.
#
# password / otp_token are generated here so no human ever types
# or sees them in a command line, script, or CI log. The static
# OTP token is single-use by django-otp design — it exists only
# to get the admin through the *first* login; a real TOTP device
# must be added via the admin UI right after.
# =========================================================
resource "random_password" "django_admin_password" {
  length  = 32
  special = true
}

resource "random_id" "django_admin_otp_token" {
  byte_length = 8
}

resource "aws_secretsmanager_secret" "django_admin" {
  name                    = "ay-l-final-project-django-admin"
  recovery_window_in_days = 0 # lab/rebuild environment - not production
  description             = "One-time bootstrap credentials for the initial Django admin superuser + static OTP token. Consumed by manage.py bootstrap_admin; not meant for ongoing login after the first TOTP device is registered."

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "django_admin" {
  secret_id = aws_secretsmanager_secret.django_admin.id
  secret_string = jsonencode({
    username  = "admin"
    email     = "admin@ay-l-final-project.local"
    password  = random_password.django_admin_password.result
    otp_token = random_id.django_admin_otp_token.hex
  })
}
