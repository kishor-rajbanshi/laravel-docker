FROM php_image

COPY --chmod=0755 \
    cron/cmd.sh \
    cron/healthcheck.sh \
    /usr/local/bin/

ENV CRON_DEFAULT_CRONTAB_FILE="/etc/crontabs/crontab"
ENV WWW_DATA_CRONTAB_FILE="/etc/crontabs/www-data"

COPY --chmod=0644 cron/crontab "$CRON_DEFAULT_CRONTAB_FILE"

RUN apk update && apk add --no-cache tini

ENTRYPOINT ["tini", "--"]

CMD ["cmd.sh"]
