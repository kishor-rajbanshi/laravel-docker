#!/bin/sh

set -e

supervisor_conf_file="/etc/supervisord.conf"
user_ini_file="/var/www/html/supervisor.ini"
conf_dir="/etc/supervisor.d"

cmd_log() {
    if [ -z "${SUPERVISOR_CMD_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

if [ "${QUEUE_CONNECTION}" = "sync" ] || [ "${QUEUE_CONNECTION}" = "null" ]; then
    curl -s -X DELETE --unix-socket /var/run/docker.sock "http://localhost/containers/$(hostname)?force=true"
fi

cmd_log "${0}: info: Running envsubst on $SUPERVISOR_DEFAULT_INI_FILE to ${conf_dir}/default.ini"
envsubst <"$SUPERVISOR_DEFAULT_INI_FILE" >"${conf_dir}/default.ini"

if [ -f "$user_ini_file" ]; then
    cmd_log "${0}: info: Using $user_ini_file"
    cmd_log "${0}: info: Running envsubst on $user_ini_file to ${conf_dir}/supervisor.ini"
    envsubst <"$user_ini_file" >"${conf_dir}/supervisor.ini"
fi

exec supervisord -c "$supervisor_conf_file"
