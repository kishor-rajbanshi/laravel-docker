#!/bin/sh

conf_file="/var/www/html/vite.config.js"

if grep -q "server:" "$conf_file"; then
    if grep -q "host:" "$conf_file"; then
        sed -i "s/host: '[^']*'/host: '0.0.0.0'/" "$conf_file"
    else
        sed -i '/server:/a\        host: '\''0.0.0.0'\'',' "$conf_file"
    fi
    if grep -q "hmr: { host:" "$conf_file"; then
        sed -i "s/hmr: { host: '[^']*' }/hmr: { host: 'localhost' }/" "$conf_file"
    else
        sed -i '/server:/a\        hmr: { host: '\''localhost'\'' },' "$conf_file"
    fi
else
    sed -i '/export default defineConfig({/a\    server: {\n        host: '\''0.0.0.0'\'',\n        hmr: { host: '\''localhost'\'' }\n    },' "$conf_file"
fi
