#!/bin/sh
set -e

echo "[entrypoint] Applying database migrations..."
python myproject/manage.py migrate --noinput

echo "[entrypoint] Collecting static files..."
python myproject/manage.py collectstatic --noinput

echo "[entrypoint] Starting Gunicorn..."
exec gunicorn --chdir /app/myproject myproject.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 2 \
    --timeout 60
