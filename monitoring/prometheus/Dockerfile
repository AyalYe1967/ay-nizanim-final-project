# docker/prometheus/Dockerfile
#
# Wraps the official Prometheus image with our baked-in scrape config
# (Master Plan section 1.1 - wrapping official images at build time).
# Version pinned deliberately to v3.14.0 (current stable) - never `latest`,
# for reproducible builds and because the ECR repo is IMMUTABLE anyway.
FROM prom/prometheus:v3.14.0

# Replaces the default config with ours. The upstream image's default CMD
# already points to this exact path, so no need to override --config.file.
COPY prometheus.yml /etc/prometheus/prometheus.yml

# Local TSDB is only a short-lived buffer - long-term storage happens via
# remote_write to Amazon Managed Service for Prometheus (AMP), not local
# disk (see prometheus.yml). 2h retention is enough to absorb brief
# remote_write backpressure/retries without needing persistent storage
# (EFS/EBS) on the Fargate task.
CMD ["--config.file=/etc/prometheus/prometheus.yml", \
     "--storage.tsdb.path=/prometheus", \
     "--storage.tsdb.retention.time=2h", \
     "--web.console.libraries=/usr/share/prometheus/console_libraries", \
     "--web.console.templates=/usr/share/prometheus/consoles"]