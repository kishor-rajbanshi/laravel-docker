#!/bin/sh

set -e

if ! pgrep -x supervisord >/dev/null; then
	echo "❌ Supervisord is not running"
	exit 1
fi

if supervisorctl status | awk '{print $2}' | grep -vq RUNNING; then
	echo "❌ One or more supervisor-managed programs are not running"
	exit 1
fi

echo "✅ All supervisor-managed programs are running"
exit 0
