FROM funkwhale/front:latest AS front

FROM funkwhale/api:latest

# Combined single-service image for Railway: gunicorn + celery (worker -B) + nginx
# in one container sharing one volume — Railway volumes can't be shared across services.
USER root
RUN apk add --no-cache nginx gettext

COPY --from=front /usr/share/nginx/html /usr/share/nginx/html
COPY --from=front /etc/nginx/templates/default.conf.template /etc/nginx/default.conf.template
COPY --from=front /etc/nginx/funkwhale_proxy.conf /etc/nginx/funkwhale_proxy.conf

COPY railway-start.sh /railway-start.sh
RUN chmod +x /railway-start.sh

ENTRYPOINT ["/railway-start.sh"]
