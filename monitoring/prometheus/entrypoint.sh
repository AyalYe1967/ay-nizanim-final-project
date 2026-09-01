#!/bin/sh
set -e

CONFIG_FILE=/etc/prometheus/prometheus.yml
LOCAL_OVERRIDE=/etc/prometheus/prometheus.local.yml

# If a local override was bind-mounted in (see docker-compose.yml), copy its
# content into the real config path. This is a plain content-copy, not a
# rename, so it works fine even though CONFIG_FILE started life as a COPY
# from the image build - it's a normal writable file, not a mount point.
if [ -f "$LOCAL_OVERRIDE" ]; then
  cp "$LOCAL_OVERRIDE" "$CONFIG_FILE"
fi

sed -i "s#AMP_REMOTE_WRITE_URL_PLACEHOLDER#${AMP_REMOTE_WRITE_URL}#" "$CONFIG_FILE"
exec /bin/prometheus "$@"