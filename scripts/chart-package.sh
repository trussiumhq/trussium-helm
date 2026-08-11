#!/bin/sh

set -eu

repository_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
distribution_directory="$repository_root/dist"

"$repository_root/scripts/helm-validate.sh"
mkdir -p "$distribution_directory"
find "$distribution_directory" -maxdepth 1 -type f -name 'trussium-*.tgz' -delete
helm package "$repository_root/charts/trussium" --destination "$distribution_directory"
"$repository_root/scripts/package-smoke-test.sh" "$distribution_directory"
