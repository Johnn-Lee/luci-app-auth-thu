#!/bin/sh

set -eu

REPOSITORY="Johnn-Lee/luci-app-auth-thu"
BASE_URL="https://github.com/$REPOSITORY/releases/latest/download"
KEY_SHA256="5e016e0c1d881bbecc1daacfa3114fa75aaa2456e3a5906fc03553a6b4f01a2d"
TMP_DIR="$(mktemp -d /tmp/luci-app-auth-thu-install.XXXXXX)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

if command -v apk >/dev/null 2>&1; then
    PACKAGE="$TMP_DIR/luci-app-auth-thu.apk"
    KEY="$TMP_DIR/auth-thu.pem"
    echo "Downloading latest signed APK release..."
    wget -O "$PACKAGE" "$BASE_URL/luci-app-auth-thu.apk"
    wget -O "$KEY" "$BASE_URL/auth-thu.pem"
    printf '%s  %s\n' "$KEY_SHA256" "$KEY" | sha256sum -c - >/dev/null
    # First-use trust is bootstrapped by this HTTPS-fetched script and pinned key.
    if [ -f /etc/apk/keys/auth-thu.pem ]; then
        cmp -s "$KEY" /etc/apk/keys/auth-thu.pem || {
            echo 'Existing project key differs; refusing to replace it.' >&2
            exit 1
        }
    else
        mkdir -p /etc/apk/keys
        cp "$KEY" /etc/apk/keys/auth-thu.pem
        chmod 0644 /etc/apk/keys/auth-thu.pem
    fi
    echo "Installing luci-app-auth-thu..."
    apk add "$PACKAGE"
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
