#!/bin/sh
set -e

export FUNKWHALE_API_HOST="${FUNKWHALE_API_HOST:-127.0.0.1}"
export FUNKWHALE_API_PORT="${FUNKWHALE_API_PORT:-5000}"
export NGINX_MAX_BODY_SIZE="${NGINX_MAX_BODY_SIZE:-500M}"
export MEDIA_ROOT="${MEDIA_ROOT:-/srv/funkwhale/data/media}"
export STATIC_ROOT="${STATIC_ROOT:-/srv/funkwhale/data/static}"
export MUSIC_DIRECTORY_PATH="${MUSIC_DIRECTORY_PATH:-/srv/funkwhale/data/music}"
export MUSIC_DIRECTORY_SERVE_PATH="${MUSIC_DIRECTORY_SERVE_PATH:-$MUSIC_DIRECTORY_PATH}"
export FUNKWHALE_PROTOCOL="${FUNKWHALE_PROTOCOL:-https}"
export DJANGO_SETTINGS_MODULE="${DJANGO_SETTINGS_MODULE:-config.settings.production}"

mkdir -p "$MEDIA_ROOT" "$STATIC_ROOT" "$MUSIC_DIRECTORY_PATH" /run/nginx

envsubst '${FUNKWHALE_API_HOST} ${FUNKWHALE_API_PORT} ${NGINX_MAX_BODY_SIZE} ${MEDIA_ROOT} ${MUSIC_DIRECTORY_PATH} ${FUNKWHALE_PROTOCOL} ${FUNKWHALE_HOSTNAME}' \
  < /etc/nginx/default.conf.template > /etc/nginx/http.d/default.conf

funkwhale-manage migrate --noinput
funkwhale-manage collectstatic --noinput

# First-boot admin; user exists already -> ignore
if [ -n "$FUNKWHALE_ADMIN_USERNAME" ]; then
  funkwhale-manage fw users create --superuser \
    -u "$FUNKWHALE_ADMIN_USERNAME" \
    -e "${FUNKWHALE_ADMIN_EMAIL:-admin@$FUNKWHALE_HOSTNAME}" \
    -p "$FUNKWHALE_ADMIN_PASSWORD" || true
fi

celery --app funkwhale_api.taskapp worker -B -s /tmp/celerybeat-schedule \
  --loglevel INFO --concurrency="${CELERYD_CONCURRENCY:-2}" &

nginx

exec gunicorn config.asgi:application \
  --workers "${FUNKWHALE_WEB_WORKERS:-2}" \
  --worker-class uvicorn.workers.UvicornWorker \
  --bind 127.0.0.1:"${FUNKWHALE_API_PORT}"
