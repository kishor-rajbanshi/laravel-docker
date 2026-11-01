#!/bin/sh

set -e

username="$1"

apk update && apk add --no-cache shadow

usermod -u "$USER_ID" "$username"
groupmod -g "$GROUP_ID" "$username"
