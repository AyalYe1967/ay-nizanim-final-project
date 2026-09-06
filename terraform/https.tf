locals {
  domain_name     = var.domain_name == null || trimspace(var.domain_name) == "" ? null : trimsuffix(lower(trimspace(var.domain_name)), ".")
  route53_zone_id = var.route53_zone_id == null || trimspace(var.route53_zone_id) == "" ? null : trimspace(var.route53_zone_id)
  existing_certificate_arn = (
    var.acm_certificate_arn == null || trimspace(var.acm_certificate_arn) == ""
    ? null
    : trimspace(var.acm_certificate_arn)
  )

  manage_certificate = local.domain_name != null && local.route53_zone_id != null && local.existing_certificate_arn == null
  effective_certificate_arn = local.domain_name == null ? null : (
    local.existing_certificate_arn != null
    ? local.existing_certificate_arn
    : try(aws_acm_certificate_validation.status_page[0].certificate_arn, null)
  )
  status_page_url = local.domain_name == null ? "http://${module.alb.dns_name}" : format(
    "%s://%s",
    local.effective_certificate_arn == null ? "http" : "https",
    local.domain_name
  )
}

resource "aws_acm_certificate" "status_page" {
  count = local.manage_certificate ? 1 : 0

  domain_name       = local.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_route53_record" "certificate_validation" {
  for_each = local.manage_certificate ? {
    for option in aws_acm_certificate.status_page[0].domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  } : {}

  allow_overwrite = true
  zone_id         = local.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
}

resource "aws_acm_certificate_validation" "status_page" {
  count = local.manage_certificate ? 1 : 0

  certificate_arn         = aws_acm_certificate.status_page[0].arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]
}

resource "aws_route53_record" "status_page" {
  count = local.domain_name != null && local.route53_zone_id != null ? 1 : 0

  zone_id = local.route53_zone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}
