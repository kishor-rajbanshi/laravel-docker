#!/bin/sh
set -e

if ! pgrep -x crond >/dev/null; then
	echo "❌ ACME: cron daemon is not running"
	exit 1
fi

if ! crontab -u root -l >/dev/null; then
	echo "❌ ACME: expected cron job file (root) is not installed"
	exit 1
fi

echo "✅ ACME: cron is running"
exit 0
