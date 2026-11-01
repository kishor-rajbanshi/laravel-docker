FROM php_image

RUN apk update && apk add --no-cache tini

RUN curl -sS https://getcomposer.org/installer | \
    php -- --install-dir=/usr/local/bin --filename=composer

USER www-data

ENTRYPOINT ["tini", "--", "composer"]
