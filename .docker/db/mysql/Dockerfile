# syntax=docker/dockerfile:1
# check=error=true
# escape=\

ARG DB_VERSION

FROM mysql:"${DB_VERSION:-latest}"

WORKDIR /var/www

COPY --chmod=0755 \
    .docker/permissions.sh \
    .docker/db/mysql/cmd.sh \
    .docker/db/mysql/healthcheck.sh \
    /usr/local/bin/

HEALTHCHECK --start-period=12s \
    CMD ["healthcheck.sh"]

RUN --mount=type=bind,source=.,target=/mnt \
    if [ -f /mnt/my.cnf ]; then \
        cp /mnt/my.cnf .; \
        chown mysql:mysql my.cnf; \
    fi

CMD ["cmd.sh"]
