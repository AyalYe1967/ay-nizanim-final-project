FROM prom/prometheus:v3.14.0

USER root

COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && chown nobody:nobody /etc/prometheus/prometheus.yml /etc/prometheus

USER nobody

ENTRYPOINT ["/entrypoint.sh"]
CMD ["--config.file=/etc/prometheus/prometheus.yml", \
     "--storage.tsdb.path=/prometheus", \
     "--storage.tsdb.retention.time=2h", \
     "--web.console.libraries=/usr/share/prometheus/console_libraries", \
     "--web.console.templates=/usr/share/prometheus/consoles"]