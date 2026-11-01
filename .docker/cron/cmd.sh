#!/bin/sh

set -e

user_crontab_file="/var/www/html/crontab"

cmd_log() {
    if [ -z "${CRON_CMD_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

if [ "${CRON_ENABLED}" != "true" ]; then
    curl -s -X DELETE --unix-socket /var/run/docker.sock "http://localhost/containers/$(hostname)?force=true"
fi

if [ -f "$user_crontab_file" ]; then
    cmd_log "${0}: info: Using $user_crontab_file"
    ln -sf "$user_crontab_file" "$WWW_DATA_CRONTAB_FILE"
else
    cmd_log "${0}: info: No $user_crontab_file found — using default configuration"
    ln -sf "$CRON_DEFAULT_CRONTAB_FILE" "$WWW_DATA_CRONTAB_FILE"
fi

exec crond -f -d 8 -l 8
