#!/bin/sh

set -e

user_conf_file="/var/www/html/nginx.conf"
conf_template_file="/etc/nginx/templates/default.conf.template"

cmd_log() {
    if [ -z "${NGINX_CMD_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

if [ -f "$user_conf_file" ]; then
    cmd_log "${0}: info: Using $user_conf_file"
    ln -sf "$user_conf_file" "$conf_template_file"
else
    cmd_log "${0}: info: No $user_conf_file found — using default configuration"
    ln -sf "$NGINX_DEFAULT_CONF_FILE" "$conf_template_file"
fi

permissions.sh nginx

if [ "${APP_DEBUG}" != "false" ] && command -v nginx-debug >/dev/null; then
    cmd_log "${0}: info: Debug mode enabled, using nginx-debug"
    /docker-entrypoint.sh nginx-debug -g 'daemon off;'
else
    /docker-entrypoint.sh nginx -g 'daemon off;'
fi
