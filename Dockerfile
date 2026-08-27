FROM python:3.10-slim-bookworm

# Status-Page 2.x requires Python 3.10+.
# These OS packages are needed to install/build Python dependencies such as
# psycopg2 (PostgreSQL driver) and Pillow.
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    libjpeg62-turbo-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/status-page

# Copy the exact Status-Page source directory supplied with the assignment ZIP.
COPY status-page/ /opt/status-page/

# Install the application's Python requirements.
RUN python -m pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Status-Page requires statuspage/statuspage/configuration.py.
# We keep our Docker-specific version beside the Dockerfile and copy it
# into the location expected by the supplied application.
COPY configuration.py /opt/status-page/statuspage/statuspage/configuration.py

WORKDIR /opt/status-page/statuspage

EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000", "--insecure"]
