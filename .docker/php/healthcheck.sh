#!/bin/sh

set -e

if ! cgi-fcgi -bind -connect 127.0.0.1:9000 >/dev/null; then
    echo "❌ Could not connect to PHP-FPM on 9000"
    exit 1
fi

echo "✅ PHP-FPM is running and accepting connections on 9000"
exit 0
