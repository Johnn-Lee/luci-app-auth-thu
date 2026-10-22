#!/usr/bin/env bash
set -euo pipefail
era="$1"
package="$2"
public="$3"
rootfs_url="$4"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
wget -q "$rootfs_url" -O "$tmp/rootfs.tar.gz"
mkdir -p "$tmp/root" "$tmp/keys"
tar -xzf "$tmp/rootfs.tar.gz" -C "$tmp/root"
root="$tmp/root"
loader="$root/lib/ld-musl-x86_64.so.1"
if [ "$era" = apk ]; then
    cp "$public" "$tmp/keys/auth-thu.pem"
    "$loader" --library-path "$root/lib:$root/usr/lib" "$root/usr/bin/apk" \
        --root "$root" --keys-dir "$tmp/keys" --repositories-file /dev/null \
        --network=no --scripts=no add --usermode "$package"
else
    mkdir -p "$root/tmp/lock"
    "$loader" --library-path "$root/lib:$root/usr/lib" "$root/bin/opkg" \
        --conf "$root/etc/opkg.conf" --offline-root "$root" install "$package"
fi
test -x "$root/etc/init.d/goauthing"
test -x "$root/usr/libexec/auth-thu-download"
test -f "$root/www/luci-static/resources/view/goauthing/setting.js"
echo 'Isolated installation passed (package scripts disabled/deferred).'
