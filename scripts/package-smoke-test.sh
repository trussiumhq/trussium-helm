#!/bin/sh

set -eu

repository_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
distribution_directory="${1:-$repository_root/dist}"
package="$(find "$distribution_directory" -maxdepth 1 -type f -name 'trussium-*.tgz' -print | head -n 1)"

if [ -z "$package" ]; then
    echo "no packaged Trussium chart found in $distribution_directory" >&2
    exit 1
fi

if [ "$(find "$distribution_directory" -maxdepth 1 -type f -name 'trussium-*.tgz' | wc -l | tr -d ' ')" != "1" ]; then
    echo "expected exactly one packaged Trussium chart" >&2
    exit 1
fi

helm show chart "$package" >/dev/null
helm show values "$package" >/dev/null
helm lint --strict "$package"

if tar -tzf "$package" | grep -Eiq 'grafana|loki|tempo|dashboard'; then
    echo "packaged chart must not bundle observability backends or dashboards" >&2
    exit 1
fi

echo "Packaged chart validation passed for $package"
