output "dns_name" {
  description = "Public DNS name of the ALB - used for Route53 alias records or direct access"
  value       = aws_lb.main.dns_name
}

output "zone_id" {
  description = "Hosted zone ID of the ALB - required when creating a Route53 alias record"
  value       = aws_lb.main.zone_id
}

output "arn" {
  value = aws_lb.main.arn
}

output "web_target_group_arn" {
  description = "ARN of the web target group - consumed by the ECS web service's load_balancer block"
  value       = aws_lb_target_group.web.arn
}

output "arn_suffix" {
  description = "ARN suffix of the ALB - required for CloudWatch metric dimensions (e.g. ALBRequestCountPerTarget autoscaling policy)"
  value       = aws_lb.main.arn_suffix
}

output "web_target_group_arn_suffix" {
  description = "ARN suffix of the web target group - required for CloudWatch metric dimensions (e.g. ALBRequestCountPerTarget autoscaling policy)"
  value       = aws_lb_target_group.web.arn_suffix
}