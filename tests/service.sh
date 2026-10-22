#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP_TEST="$(mktemp -d)"
trap 'rm -rf "$TMP_TEST"' EXIT
export TEST_LOG="$TMP_TEST/args"
export TEST_USERNAME='u ser;$(printf INJECTED)'
export TEST_PASSWORD='two words $(touch SHOULD_NOT_EXIST) $dollar "quotes" back\slash'

cat > "$TMP_TEST/core" <<'SH'
#!/bin/sh
printf '<%s>' "$@" >> "$TEST_LOG"
printf '\n' >> "$TEST_LOG"
SH
chmod +x "$TMP_TEST/core"
. "$ROOT/luci-app-auth-thu/root/etc/init.d/goauthing"
PROG="$TMP_TEST/core"
config_get() {
    case "$1" in
        username) username="$TEST_USERNAME" ;;
        password) password="$TEST_PASSWORD" ;;
    esac
}
procd_open_instance() { :; }
procd_close_instance() { :; }
procd_set_param() {
    if [ "$1" = command ]; then shift; "$@"; fi
}
cd "$TMP_TEST"
start_instance
[ ! -e SHOULD_NOT_EXIST ]
for action in deauth auth online; do
    if [ "$action" = online ]; then
        printf '<%s><%s><%s><%s><%s>\n' -u "$TEST_USERNAME" -p "$TEST_PASSWORD" "$action"
    else
        printf '<%s><%s><%s><%s><%s><%s>\n' -u "$TEST_USERNAME" -p "$TEST_PASSWORD" "$action" --insecure
    fi
done > "$TMP_TEST/expected"
cmp "$TEST_LOG" "$TMP_TEST/expected"
echo 'Service tests passed: credentials are literal arguments, no shell expansion.'
