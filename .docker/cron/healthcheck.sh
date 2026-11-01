#!/bin/sh
set -e

if ! pgrep -x crond >/dev/null; then
	echo "❌ Cron daemon is not running"
	exit 1
fi

if ! crontab -u www-data -l >/dev/null; then
	echo "❌ Expected cron job file (${WWW_DATA_CRONTAB_FILE}) is not installed"
	exit 1
fi

echo "✅ Cron is running"
exit 0
