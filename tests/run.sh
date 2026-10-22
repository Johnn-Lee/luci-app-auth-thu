#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
for file in feed.sh scripts/*.sh tests/*.sh luci-app-auth-thu/root/etc/init.d/goauthing luci-app-auth-thu/root/usr/libexec/auth-thu-download; do
    sh -n "$file"
done
sh tests/service.sh
sh tests/download.sh
sh tests/installer.sh
node tests/view.cjs
node -e 'const fs=require("fs"); for (const p of ["luci-app-auth-thu/root/usr/share/rpcd/acl.d/luci-app-auth-thu.json","luci-app-auth-thu/root/usr/share/luci/menu.d/luci-app-auth-thu.json"]) JSON.parse(fs.readFileSync(p));'
actual="$(sha256sum keys/auth-thu.pem | cut -d ' ' -f 1)"
grep -q "KEY_SHA256=\"$actual\"" feed.sh
echo 'Syntax, JSON and installer key pin checks passed.'
