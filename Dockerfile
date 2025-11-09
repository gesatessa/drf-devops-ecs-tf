FROM python:3.13-alpine3.21
LABEL maintainer="gesatessa"

ENV PYTHONUNBUFFERED 1

ARG UID=101

# Copy requirements files
COPY ./requirements.txt ./requirements.dev.txt /tmp/

# Copy project code and scripts
COPY ./app /app
COPY ./scripts /scripts

WORKDIR /app
EXPOSE 8000

ARG DEV=false
RUN pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client jpeg-dev && \
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev zlib zlib-dev linux-headers && \
    pip install -r /tmp/requirements.txt && \
    if [ "$DEV" = "true" ]; then pip install -r /tmp/requirements.dev.txt ; fi && \
    rm -rf /tmp && \
    apk del .tmp-build-deps && \
    adduser --uid $UID --disabled-password --no-create-home django-user && \
    mkdir -p /vol/web/media /vol/web/static && \
    chown -R django-user:django-user /vol/web && \
    chmod -R 755 /vol/web && \
    chmod -R +x /scripts

ENV PATH="/scripts:/py/bin:$PATH"

USER django-user

# when deploying to ECS we need to have specified it in Dockerfile
VOLUME /vol/web/media
VOLUME /vol/web/static

CMD ["run.sh"]
