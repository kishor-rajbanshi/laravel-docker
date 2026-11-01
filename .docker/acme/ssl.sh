#!/bin/sh

set -e

map_file="/acme.sh/map"

cmd_log() {
    if [ -z "${ACME_CMD_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

if [ ! -f "$map_file" ]; then
    cmd_log "${0}: info: No $map_file found — skipping SSL generation"
    exit 0
fi

unique_name() {
    dir="$1"
    length="$2"

    while :; do
        rand=$(head -c 512 /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c "$length")
        if [ ! -e "${dir}/$rand" ]; then
            echo "$rand"
            return
        fi
    done
}

cmd_log "${0}: info: Generating SSL certificates..."

while IFS= read -r line; do
    domains=$(
        echo "$line" |
            awk -F'=>' '{print $1}' |
            xargs -n1 |
            awk '{ if ($0 ~ /\*/) print "-d \""$0"\""; else print "-d "$0 }' |
            tr "\n" " "
    )

    webroot=$(echo "$line" | awk -F'=>' '{print $2}' | xargs)
    first_domain=$(printf "%s" "$line" | awk -F'=>' '{split($1,a," "); print a[1]}')

    cert_home_dir="/acme.sh/$(unique_name "/acme.sh/" 13)"
    fullchain_file="/ssl/$(unique_name "/ssl/" 14).pem"
    key_file="/ssl/$(unique_name "/ssl/" 8).pem"

    acme.sh \
        ${app_debug:+--debug 3} \
        ${ACME_EAB_KID:+--eab-kid "$ACME_EAB_KID"} \
        ${ACME_EAB_HMAC_KEY:+--eab-hmac-key "$ACME_EAB_HMAC_KEY"} \
        --server "${ACME_CA_SERVER}" \
        --cert-home "$cert_home_dir" \
        --issue $domains \
        -w "$webroot" \
        --renew-hook 'id=$(curl -s --unix-socket /var/run/docker.sock \
            -H "Content-Type: application/json" \
            -X POST "http://localhost/containers/${COMPOSE_PROJECT_NAME}-nginx/exec" \
            -d "{\"AttachStdout\":true,\"AttachStderr\":true,\"Cmd\":[\"nginx\",\"-s\",\"reload\"]}" \
            | sed -n "s/.*\"Id\":\"\([^\"]*\)\".*/\1/p"); \
            curl -s --unix-socket /var/run/docker.sock \
            -H "Content-Type: application/json" \
            -X POST "http://localhost/exec/$id/start" \
            -d "{\"Detach\":false,\"Tty\":false}"'

    rm -rf "${webroot}/.well-known"

    acme.sh \
        --install-cert \
        --cert-home "$cert_home_dir" \
        -d "$first_domain" \
        --fullchain-file "$fullchain_file" \
        --key-file "$key_file"

    chown acme:acme "$fullchain_file" "$key_file"
done <"$map_file"

rm -rf "$map_file"

cmd_log "${0}: info: SSL generation complete"

cmd_log "${0}: info: Restarting ${COMPOSE_PROJECT_NAME}-nginx"

curl --unix-socket /var/run/docker.sock -X POST "http://localhost/containers/${COMPOSE_PROJECT_NAME}-nginx/restart"
