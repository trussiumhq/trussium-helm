#!/bin/sh

set -eu

repository_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
chart="$repository_root/charts/trussium"
kube_version="${1:-}"

case "$kube_version" in
    ''|*[!0-9.]*|*.*.*.*|.*|*.|*..*)
        echo "usage: $0 MAJOR.MINOR.PATCH" >&2
        exit 2
        ;;
esac

rendered="$(mktemp)"
trap 'rm -f "$rendered"' EXIT INT TERM

helm lint --strict "$chart" --kube-version "$kube_version"
helm template trussium "$chart" --namespace trussium-system \
    --kube-version "$kube_version" >"$rendered"

grep -q '^kind: Deployment$' "$rendered"
grep -q '^kind: Service$' "$rendered"
echo "Kubernetes $kube_version chart validation passed"
