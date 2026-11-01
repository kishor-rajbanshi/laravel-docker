# syntax=docker/dockerfile:1
# check=error=true
# escape=\

ARG DB_VERSION

FROM mariadb:${DB_VERSION:-latest}

COPY --chmod=0755 \
    .docker/permissions.sh \
    .docker/db/mariadb/cmd.sh \
    .docker/db/mariadb/healthcheck.sh \
    /usr/local/bin/

HEALTHCHECK --start-period=12s \
    CMD ["healthcheck.sh"]


RUN --mount=type=bind,source=.,target=app \
    cp app/mariadb.cnf . 2>/dev/null || true

CMD ["cmd.sh"]
