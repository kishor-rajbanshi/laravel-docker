#!/bin/sh

set -e

env_file="/var/www/html/.env"

cmd_log() {
    if [ -z "${ACME_CMD_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

cmd_log "${0}: info: Setting up mail notifications..."

while IFS='=' read -r key value || [ -n "$key" ]; do
    case "$key" in
    ACME_NOTIFY_*)
        value=$(echo "$value" | sed -e 's/^["'\'']//;s/["'\'']$//')
        key="${key#ACME_NOTIFY_}"
        export "$key=$value"
        ;;
    esac
done <"$env_file"

if [ -z "$HOOKS" ]; then
    cmd_log "${0}: info: Notification hook not defined. Skipping configuration"
    exit 0
fi

source=$([ -n "$SOURCE" ] && echo "$SOURCE" || echo "${COMPOSE_PROJECT_NAME}")

for hook in $HOOKS; do
    cmd_log "${0}: info: Using '${hook}' notification hook"

    acme.sh \
        --set-notify \
        --notify-hook "$hook" \
        --notify-source "$source" \
        ${app_debug:+--debug 3} \
        ${LEVEL:+--notify-level "$LEVEL"} \
        ${MODE:+--notify-mode "$MODE"}
done

cmd_log "${0}: info: Notification setup complete"
