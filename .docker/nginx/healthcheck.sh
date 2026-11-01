#!/bin/sh

set -e

health_signal_file="/tmp/health_signal"

ports=$(
    ss -ltnp 2>/dev/null |
        grep nginx |
        awk '{print $4}' |
        awk -F: '{print $NF}' |
        sort -u
)

if [ -z "$ports" ]; then
    echo "❌ HTTP check failed: nginx not listening on any port"
    exit 1
fi

trap 'rm -f "$health_signal_file"' EXIT HUP INT QUIT TERM

for port in $ports; do
    (curl -sfkL -o /dev/null "http://127.0.0.1:$port/" && touch "$health_signal_file") &
done

while true; do
    if [ -f "$health_signal_file" ]; then
        echo "✅ HTTP check passed: localhost is reachable"
        exit 0
    fi

    if [ "$(jobs | wc -l)" -eq 0 ]; then
        echo "❌ HTTP check failed: localhost is not reachable"
        exit 1
    fi

    sleep 0.1
done
