#!/bin/sh

set -e

user_conf_file="/var/www/app/config.inc.php"
conf_dir="/etc/phpmyadmin/conf.d/"

cmd_log() {
    if [ -z "${PHPMYADMIN_CMD_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

if [ "${PHPMYADMIN_ENABLED}" != "true" ] || ([ "${DB_CONNECTION}" != "mysql" ] && [ "${DB_CONNECTION}" != "mariadb" ]); then
    while true; do
        status="$(
            curl -s --unix-socket /var/run/docker.sock http://localhost/containers/${COMPOSE_PROJECT_NAME}-nginx/json |
                jq -r '.State.Status' 2>/dev/null
        )"

        if [ "$status" = "running" ]; then
            break
        fi

        cmd_log "${0}: info: Waiting for ${COMPOSE_PROJECT_NAME}-nginx to start"

        sleep 1
    done

    curl -s -X DELETE --unix-socket /var/run/docker.sock "http://localhost/containers/$(hostname)?force=true"
fi

if [ -f "$user_conf_file" ]; then
    cmd_log "${0}: info: Using $user_conf_file"
    mkdir -p "$conf_dir"
    ln -sf "$user_conf_file" "$conf_dir"
fi

/docker-entrypoint.sh php-fpm
