#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP_TEST="$(mktemp -d)"
trap 'rm -rf "$TMP_TEST"' EXIT
export TEST_ROOT="$ROOT" TEST_APK_LOG="$TMP_TEST/apk-log" TEST_OPKG_LOG="$TMP_TEST/opkg-log"
mkdir "$TMP_TEST/bin" "$TMP_TEST/keys"
sed "s|/etc/apk/keys|$TMP_TEST/keys|g" "$ROOT/feed.sh" > "$TMP_TEST/installer"
cat > "$TMP_TEST/bin/wget" <<'SH'
#!/bin/sh
out="$2"
case "$3" in
    *.pem)
        if [ "${TEST_BAD_KEY:-0}" = 1 ]; then printf 'wrong key' > "$out";
        else cp "$TEST_ROOT/keys/auth-thu.pem" "$out"; fi ;;
    *) printf 'package fixture' > "$out" ;;
esac
SH
cat > "$TMP_TEST/bin/apk" <<'SH'
#!/bin/sh
[ "$#" = 2 ] && [ "$1" = add ] || exit 1
printf '%s\n' "$@" > "$TEST_APK_LOG"
exit "${TEST_APK_EXIT:-0}"
SH
cat > "$TMP_TEST/bin/opkg" <<'SH'
#!/bin/sh
[ "$#" = 2 ] && [ "$1" = install ] || exit 1
printf '%s\n' "$@" > "$TEST_OPKG_LOG"
SH
chmod +x "$TMP_TEST/bin/"*
export PATH="$TMP_TEST/bin:$PATH"
sh "$TMP_TEST/installer" > "$TMP_TEST/output" 2>&1
test -s "$TEST_APK_LOG"
cmp "$TMP_TEST/keys/auth-thu.pem" "$ROOT/keys/auth-thu.pem"
rm "$TEST_APK_LOG"
if TEST_BAD_KEY=1 sh "$TMP_TEST/installer" > "$TMP_TEST/output" 2>&1; then exit 1; fi
[ ! -e "$TEST_APK_LOG" ]
printf 'existing unrelated key' > "$TMP_TEST/keys/auth-thu.pem"
if sh "$TMP_TEST/installer" > "$TMP_TEST/output" 2>&1; then exit 1; fi
[ ! -e "$TEST_APK_LOG" ]
test "$(cat "$TMP_TEST/keys/auth-thu.pem")" = 'existing unrelated key'
cp "$ROOT/keys/auth-thu.pem" "$TMP_TEST/keys/auth-thu.pem"
if TEST_APK_EXIT=1 sh "$TMP_TEST/installer" > "$TMP_TEST/output" 2>&1; then exit 1; fi
if grep -q 'installed successfully' "$TMP_TEST/output"; then exit 1; fi
mv "$TMP_TEST/bin/apk" "$TMP_TEST/bin/apk.disabled"
sh "$TMP_TEST/installer" > "$TMP_TEST/output" 2>&1
test -s "$TEST_OPKG_LOG"
echo 'Installer tests passed: pinned trust, key conflicts, install failures and normal opkg path.'
