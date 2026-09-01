FROM python:3.10-slim-bookworm

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


COPY configuration.py /opt/status-page/statuspage/statuspage/configuration.py

WORKDIR /opt/status-page/statuspage

EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000", "--insecure"]
