#!/bin/sh

set -e

if mysql -u "${DB_USERNAME}" -p"${DB_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ MySQL connection successful"
    exit 0
fi

echo "❌ MySQL is down or credentials/auth failed"
exit 1
