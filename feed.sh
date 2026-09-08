#!/bin/sh

set -e

REPOSITORY="Johnn-Lee/luci-app-auth-thu"
BASE_URL="https://github.com/$REPOSITORY/releases/latest/download"
TMP_DIR="/tmp/luci-app-auth-thu-install"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

mkdir -p "$TMP_DIR"

if command -v apk >/dev/null 2>&1; then
    PACKAGE="$TMP_DIR/luci-app-auth-thu.apk"
    echo "Downloading latest APK release..."
    wget -O "$PACKAGE" "$BASE_URL/luci-app-auth-thu.apk"
    echo "Installing luci-app-auth-thu..."
    apk add --allow-untrusted "$PACKAGE"
elif command -v opkg >/dev/null 2>&1; then
    PACKAGE="$TMP_DIR/luci-app-auth-thu.ipk"
    echo "Downloading latest OPKG release..."
    wget -O "$PACKAGE" "$BASE_URL/luci-app-auth-thu.ipk"
    echo "Installing luci-app-auth-thu..."
    opkg install "$PACKAGE"
else
    echo "Error: neither apk nor opkg was found."
    exit 1
fi

echo "luci-app-auth-thu installed successfully."
