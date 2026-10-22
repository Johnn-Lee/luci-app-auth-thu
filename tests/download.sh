#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP_TEST="$(mktemp -d)"
trap 'rm -rf "$TMP_TEST"' EXIT
mkdir "$TMP_TEST/bin" "$TMP_TEST/dest"
export TEST_DEST="$TMP_TEST/dest"
export TEST_ELF=/usr/bin/printf
# Only redirect the production destination into a sandbox; its download,
# validation, permission checks, cleanup and rename logic run unchanged.
sed "s|/usr/bin/goauthing|$TEST_DEST/goauthing|;s|/usr/bin/.goauthing|$TEST_DEST/.goauthing|" \
    "$ROOT/luci-app-auth-thu/root/usr/libexec/auth-thu-download" > "$TMP_TEST/helper"
cat > "$TMP_TEST/bin/wget" <<'SH'
#!/bin/sh
while [ "$#" -gt 0 ]; do
    case "$1" in -T) shift 2 ;; -O) out="$2"; shift 2 ;; *) url="$1"; shift ;; esac
done
case "$url" in
    *network-fail*) exit 1 ;;
    *html*) printf '<html>not a binary</html>' > "$out" ;;
    *wrong-arch*) printf '\177ELFwrong-architecture' > "$out" ;;
    *) cp "$TEST_ELF" "$out" ;;
esac
SH
for cmd in chmod mv mktemp; do
    cat > "$TMP_TEST/bin/$cmd" <<'SH'
#!/bin/sh
cmd="${0##*/}"
[ "${TEST_FAIL:-}" != "$cmd" ] || exit 1
exec "/bin/$cmd" "$@"
SH
done
chmod +x "$TMP_TEST/bin/"*
export PATH="$TMP_TEST/bin:$PATH"

for scenario in network-fail html wrong-arch chmod mv mktemp; do
    printf 'old core\n' > "$TEST_DEST/goauthing"
    cp "$TEST_DEST/goauthing" "$TMP_TEST/old"
    export TEST_FAIL="$scenario"
    if sh "$TMP_TEST/helper" "https://example.invalid/$scenario" > "$TMP_TEST/output" 2>&1; then
        echo "Unexpected success: $scenario" >&2; exit 1
    fi
    cmp "$TEST_DEST/goauthing" "$TMP_TEST/old"
    [ -z "$(find "$TEST_DEST" -name '.goauthing.*' -print)" ]
done
unset TEST_FAIL
sh "$TMP_TEST/helper" 'http://example.invalid/rejected' 'https://example.invalid/network-fail' 'https://example.invalid/good' > "$TMP_TEST/output" 2>&1
cmp "$TEST_DEST/goauthing" "$TEST_ELF"
[ -z "$(find "$TEST_DEST" -name '.goauthing.*' -print)" ]
echo 'Download tests passed: fallback, ELF validation, all failure paths preserve the old core.'
