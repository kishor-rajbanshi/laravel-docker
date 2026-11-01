#!/bin/sh

set -e

if mariadb -u "${DB_USERNAME}" -p"${DB_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ MariaDB connection successful"
    exit 0
fi

echo "❌ MariaDB is down or credentials/auth failed"
exit 1
