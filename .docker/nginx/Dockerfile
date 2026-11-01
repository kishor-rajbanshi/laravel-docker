# syntax=docker/dockerfile:1
# check=error=true
# escape=\

ARG NGINX_VERSION

FROM nginx:"${NGINX_VERSION:-stable}-alpine"

ENV NGINX_MAIN_CONF_FILE="/etc/nginx/nginx.conf"
ENV NGINX_DEFAULT_CONF_FILE="/etc/nginx/templates/default.conf"

WORKDIR /var/www/html

COPY --chmod=0755 \
    .docker/permissions.sh \
    .docker/nginx/cmd.sh \
    .docker/nginx/healthcheck.sh \
    /usr/local/bin/

COPY --chmod=0755 \
    .docker/nginx/65-phpmyadmin.sh \
    .docker/nginx/70-ssl.sh \
    /docker-entrypoint.d/

COPY --chown=nginx .docker/nginx/default.conf "${NGINX_DEFAULT_CONF_FILE}"

COPY . .

RUN apk update && apk add --no-cache \
    jq \
    openssl \
    python3 \
    py3-pip \
    py3-virtualenv \
    iproute2 \
    shadow

RUN python -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install --no-cache-dir crossplane

CMD ["cmd.sh"]
