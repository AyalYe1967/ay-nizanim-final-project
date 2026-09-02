output "dns_name" {
  description = "Public DNS name of the Grafana ALB - use this to access the Grafana UI"
  value       = aws_lb.grafana.dns_name
}

output "arn" {
  value = aws_lb.grafana.arn
}

output "grafana_target_group_arn" {
  description = "ARN of the Grafana target group - consumed by the ECS grafana service's load_balancer block"
  value       = aws_lb_target_group.grafana.arn
}