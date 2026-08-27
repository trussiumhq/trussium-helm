#!/bin/sh

set -eu

repository_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
chart_file="$repository_root/charts/trussium/Chart.yaml"
contract_file="$repository_root/scripts/chart-contract-test.sh"
readme_file="$repository_root/README.md"
compatibility_file="$repository_root/docs/COMPATIBILITY.md"

fail() {
    echo "runtime proposal failure: $*" >&2
    exit 1
}

runtime_version="${1:-${TRUSSIUM_RUNTIME_VERSION:-}}"
if [ -z "$runtime_version" ]; then
    command -v curl >/dev/null 2>&1 || fail "curl is required for release lookup"
    command -v jq >/dev/null 2>&1 || fail "jq is required for release lookup"
    runtime_version="$(curl --fail --silent --show-error --location \
        -H 'Accept: application/vnd.github+json' \
        https://api.github.com/repos/trussiumhq/trussium/releases/latest | jq -r '.tag_name')"
fi

runtime_version="${runtime_version#v}"
case "$runtime_version" in
    ''|*[!0-9.]*|*.*.*.*|.*|*.|*..*) fail "runtime version must be semantic, got '$runtime_version'" ;;
esac
version_parts=$(printf '%s' "$runtime_version" | awk -F. '{print NF}')
[ "$version_parts" -eq 3 ] || fail "runtime version must be major.minor.patch, got '$runtime_version'"
runtime_series="${runtime_version%.*}.x"

current_version="$(sed -n 's/^appVersion: "\([^"]*\)"$/\1/p' "$chart_file")"
[ -n "$current_version" ] || fail "could not read chart appVersion"
if [ "$current_version" = "$runtime_version" ]; then
    echo "Runtime compatibility is already $runtime_version"
    exit 0
fi

sed -i.bak 's/^appVersion: ".*"$/appVersion: "'"$runtime_version"'"/' "$chart_file"
sed -i.bak 's#trussium:[0-9][0-9.]*#trussium:'"$runtime_version"'#' "$contract_file"
perl -0pi -e 's#(\| `[^`]+` \| )`[0-9]+\.[0-9]+\.x`( \| `>=1\.25` \|)#${1}`'"$runtime_series"'`${2}#' "$readme_file"
perl -0pi -e 's#(\| `[^`]+` \| )`[0-9]+\.[0-9]+\.x`( \| `>=1\.25` \|)#${1}`'"$runtime_series"'`${2}#' "$compatibility_file"
rm -f "$chart_file.bak" "$contract_file.bak" "$readme_file.bak" "$compatibility_file.bak"

echo "Proposed runtime compatibility update: $current_version -> $runtime_version"
