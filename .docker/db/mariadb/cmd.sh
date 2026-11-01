#!/bin/sh

set -e

data_dir="/var/db/mariadb/"
conf_dir="/etc/mysql/mariadb.conf.d/"
user_cnf_file="/var/www/mariadb.cnf"

cmd_log() {
    if [ -z "${DB_CMD_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

export MARIADB_DATABASE="${DB_DATABASE}"

if [ "$DB_USERNAME" = "root" ]; then
    export MARIADB_ROOT_PASSWORD="${DB_PASSWORD}"
else
    export MARIADB_RANDOM_ROOT_PASSWORD=true
    export MARIADB_USER="${DB_USERNAME}"
    export MARIADB_PASSWORD="${DB_PASSWORD}"
fi

mkdir -p $data_dir

echo "[mariadbd]\ndatadir=$data_dir" >"${conf_dir}/datadir.cnf"

if [ -f "$user_cnf_file" ]; then
    cmd_log "$0: info: Using $user_cnf_file"
    ln -sf "$user_cnf_file" "$conf_dir"
fi

permissions.sh mysql

docker-entrypoint.sh mariadbd
