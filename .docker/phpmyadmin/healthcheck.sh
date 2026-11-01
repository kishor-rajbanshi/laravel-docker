#!/bin/sh

if [ "${PHPMYADMIN_ENABLED}" = "true" ] && ([ "${DB_CONNECTION}" = "mysql" ] || [ "${DB_CONNECTION}" = "mariadb" ]); then
    if [ ! -f /var/www/html/index.php ]; then
        echo "❌ PhpMyAdmin index.php not found"
        exit 1
    fi

    if ! cgi-fcgi -bind -connect 127.0.0.1:9000 >/dev/null; then
        echo "❌ Could not connect to PHP-FPM on 9000"
        exit 1
    fi

    echo "✅ PHP-FPM is active on port 9000 and phpMyAdmin is accessible"
    exit 0
fi

echo "ℹ️  PhpMyAdmin check skipped (not enabled or unsupported database)"
exit 0
