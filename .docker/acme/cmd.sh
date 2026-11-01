#!/bin/sh

set -e

cmd_log() {
    if [ -z "${ACME_CMD_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

if [ "${ACME_ENABLED}" != "true" ]; then
    curl -s -X DELETE --unix-socket /var/run/docker.sock "http://localhost/containers/$(hostname)?force=true"
fi

if [ "$APP_DEBUG" = "true" ]; then
    export app_debug="true"
fi

ssl.sh

notify.sh

cmd_log "${0}: info: Starting acme daemon"

/entry.sh daemon
