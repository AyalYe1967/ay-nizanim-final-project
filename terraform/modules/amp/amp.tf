
# Amazon Managed Service for Prometheus (AMP) - long-term TSDB storage.
# Local Prometheus TSDB is only a 2h buffer (see monitoring/prometheus/Dockerfile);
# real persistence happens here via remote_write. Chosen over EFS/EBS-backed
# local storage or a single EC2+EBS host - see deviation notes.
resource "aws_prometheus_workspace" "this" {
  alias = "ay-l-final-project-amp"

  tags = var.tags
}