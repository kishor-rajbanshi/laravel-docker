#!/bin/sh

set -e

data_dir="/var/db/mysql"
conf_dir="/etc/mysql/conf.d"
user_conf_file="/var/www/my.cnf"

cmd_log() {
    if [ -z "${DB_CMD_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

export MYSQL_DATABASE="${DB_DATABASE}"

if [ "$DB_USERNAME" = "root" ]; then
    export MYSQL_ROOT_PASSWORD="${DB_PASSWORD}"
else
    export MYSQL_RANDOM_ROOT_PASSWORD=true
    export MYSQL_USER="${DB_USERNAME}"
    export MYSQL_PASSWORD="${DB_PASSWORD}"
fi

mkdir -p "$data_dir"

echo -e "[mysqld]\ndatadir=$data_dir" >"${conf_dir}/datadir.cnf"

if [ -f "$user_conf_file" ]; then
    cmd_log "${0}: info: Using $user_conf_file"
    ln -sf "$user_conf_file" "$conf_dir"
fi

# permissions.sh mysql

docker-entrypoint.sh mysqld
