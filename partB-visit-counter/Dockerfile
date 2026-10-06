# ================================================================
# Visit-Counter - Dockerfile
# Base image: python:3.12-alpine
#   * Alpine Linux is ~7 MB (vs ~75 MB for Debian slim and ~350 MB
#     for the full python image) -> smallest image, smallest attack
#     surface, fastest push/pull.
#   * Our dependencies (Flask, redis-py, gunicorn) are pure Python,
#     so no compiler / musl problem: wheels install directly.
# ================================================================
FROM python:3.12-alpine

# Python runtime settings: no .pyc files, unbuffered logs (docker logs)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_PORT=5000

WORKDIR /app

# Create an unprivileged user (security: never run as root)
RUN addgroup -S app && adduser -S -G app -H app

# ---- Docker cache optimisation ----
# Copy ONLY the requirements first: this layer (and the pip install
# below) is reused as long as requirements.txt does not change, even
# if the source code changes.
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Source code changes often -> copied last
COPY --chown=app:app app/ .

# Drop root privileges
USER app

EXPOSE 5000

# Production WSGI server (2 workers) instead of the Flask dev server
CMD ["sh", "-c", "gunicorn --workers 2 --bind 0.0.0.0:${APP_PORT} app:app"]
