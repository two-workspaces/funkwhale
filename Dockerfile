FROM funkwhale/front:2.0.12 AS front

FROM funkwhale/api:2.0.12

# Combined single-service image for Railway: gunicorn + celery (worker -B) + nginx
# in one container sharing one volume — Railway volumes can't be shared across services.
USER root
RUN apk add --no-cache nginx gettext \
    # Alpine's nginx.conf runs `worker_processes auto`, which counts host cores,
    # not the container's CPU quota: Railway Metal hosts show 48, so nginx forks
    # 48 workers (~30 MB each, ~1.5 GB idle) and the container is OOM-killed on
    # the Trial (1 GB) and Free (0.5 GB) plans. railway-start.sh only renders
    # http.d/default.conf, so the main conf can be patched here.
    && sed -i -E 's/^worker_processes[[:space:]]+auto;/worker_processes 2;/' /etc/nginx/nginx.conf \
    && grep -q '^worker_processes 2;' /etc/nginx/nginx.conf

COPY --from=front /usr/share/nginx/html /usr/share/nginx/html
COPY --from=front /etc/nginx/templates/default.conf.template /etc/nginx/default.conf.template
COPY --from=front /etc/nginx/funkwhale_proxy.conf /etc/nginx/funkwhale_proxy.conf

COPY railway-start.sh /railway-start.sh
RUN chmod +x /railway-start.sh

ENTRYPOINT ["/railway-start.sh"]
