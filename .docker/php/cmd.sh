#!/bin/sh

set -e

user_ini_file="/var/www/html/php.ini"

cmd_log() {
    if [ -z "${PHP_CMD_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

if [ "${APP_ENV}" = "production" ]; then
    cmd_log "${0}: info: Using production PHP configuration"
    ln -sf "${PHP_INI_DIR}/php.ini-production" "${PHP_INI_DIR}/php.ini"
else
    cmd_log "${0}: info: Using development PHP configuration"
    ln -sf "${PHP_INI_DIR}/php.ini-development" "${PHP_INI_DIR}/php.ini"
fi

if [ -f "$user_ini_file" ]; then
    cmd_log "${0}: info: Using $user_ini_file"
    ln -sf "$user_ini_file" "${PHP_INI_DIR}/conf.d/php.ini"
fi

permissions.sh www-data

docker-php-entrypoint php-fpm
