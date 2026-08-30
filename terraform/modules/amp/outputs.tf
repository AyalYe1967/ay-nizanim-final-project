output "workspace_id" {
  description = "AMP workspace ID - part of both the remote_write and query URLs"
  value       = aws_prometheus_workspace.this.id
}

output "workspace_arn" {
  value = aws_prometheus_workspace.this.arn
}

output "remote_write_url" {
  description = "Used in monitoring/prometheus/prometheus.yml's remote_write.url (replaces TODO_AMP_WORKSPACE_ID)"
  value       = "${aws_prometheus_workspace.this.prometheus_endpoint}api/v1/remote_write"
}

output "query_url" {
  description = "Used as the Amazon Managed Prometheus datasource URL in Grafana's datasources.yml (replaces TODO_AMP_WORKSPACE_ID)"
  value       = trimsuffix(aws_prometheus_workspace.this.prometheus_endpoint, "/")
}