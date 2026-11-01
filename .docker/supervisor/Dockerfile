FROM php_image

ARG COMPOSE_PROJECT_NAME

ENV SUPERVISOR_DEFAULT_INI_FILE="/etc/supervisor.d/templates/default.ini"
ENV SUPERVISOR_DEFAULT_PROGRAM="program:${COMPOSE_PROJECT_NAME}-worker"

COPY --chmod=0755 \
    supervisor/cmd.sh \
    supervisor/healthcheck.sh \
    /usr/local/bin/

COPY --chmod=0644 supervisor/default.ini "$SUPERVISOR_DEFAULT_INI_FILE"

RUN apk update && apk add --no-cache supervisor tini gettext

ENTRYPOINT [ "tini", "--" ]

CMD ["cmd.sh"]
