FROM nginxinc/nginx-unprivileged:1-alpine
LABEL maintainer="gesatessa"

COPY ./default.conf.tpl ./gunicorn_headers /etc/nginx
COPY ./run.sh /run.sh

ENV LISTEN_PORT=8000
ENV APP_HOST=app
ENV APP_PORT=9000

USER root

RUN mkdir -p /vol/static /vol/media && \
    chmod -R 755 /vol && \
    chown -R nginx:nginx /vol && \
    touch /etc/nginx/conf.d/default.conf && \
    chown nginx:nginx /etc/nginx/conf.d/default.conf && \
    chmod +x /run.sh

VOLUME /vol/static
VOLUME /vol/media

USER nginx

CMD ["/run.sh"]
