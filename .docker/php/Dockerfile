# syntax=docker/dockerfile:1
# check=error=true
# escape=\

ARG APP_ENV
ARG NODE_VERSION
ARG PHP_VERSION

FROM node:"${NODE_VERSION:-current}-alpine" AS node

WORKDIR /var/www

RUN --mount=type=bind,source=package.json,target=package.json,rw \
    --mount=type=bind,source=package-lock.json,target=package-lock.json,rw \
    --mount=type=cache,target=/root/.npm \
    if [ "$APP_ENV" = "production" ]; then \
        npm ci --omit=dev; \
    else \
        npm i; \
    fi

COPY . .

RUN if [ "$APP_ENV" = "production" ]; then \
        npm ci --omit=dev; \
        if npm run | grep -q " prod"; then \
            npm run prod; \
        elif npm run | grep -q " build"; then \
            npm run build; \
        fi \
    else \
        npm i; \
    fi

FROM php:"${PHP_VERSION:+${PHP_VERSION}-}fpm-alpine"

ARG PHP_EXTENSIONS
ARG PHP_DEV_EXTENSIONS

WORKDIR /var/www

COPY --chmod=0755 \
    .docker/permissions.sh \
    .docker/php/cmd.sh \
    .docker/php/healthcheck.sh \
    /usr/local/bin/

ADD --chmod=0755 \
    https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    /usr/local/bin/

RUN curl -sS https://getcomposer.org/installer | \
    php -- --install-dir=/usr/local/bin --filename=composer

RUN curl -o /usr/local/bin/php-fpm-healthcheck \
    https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck

RUN apk update && apk add --no-cache fcgi shadow

RUN if [ -n "${PHP_EXTENSIONS}" ]; then \
        install-php-extensions "${PHP_EXTENSIONS}"; \
    fi
    
RUN if [ "$APP_ENV" != "production" ] && [ -n "${PHP_DEV_EXTENSIONS}" ]; then \
        install-php-extensions "${PHP_DEV_EXTENSIONS}"; \
    fi

COPY --from=node /var/www/ .

RUN --mount=type=cache,target=/root/.composer \
    if [ "$APP_ENV" = "production" ]; then \ 
        composer install --no-dev --optimize-autoloader --no-progress --no-interaction --prefer-dist; \
    else \
        composer install; \
    fi

CMD ["cmd.sh"]
