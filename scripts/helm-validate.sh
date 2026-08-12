#!/bin/sh

set -eu

repository_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
chart="$repository_root/charts/trussium"
custom_values="$repository_root/tests/fixtures/custom-values.yaml"
default_render="$(mktemp)"
custom_render="$(mktemp)"

cleanup() {
    rm -f "$default_render" "$custom_render"
}

trap cleanup EXIT INT TERM

command -v helm >/dev/null 2>&1 || {
    echo "helm is required for chart validation" >&2
    exit 1
}

helm lint --strict "$chart"
helm lint --strict "$chart" --values "$custom_values"
helm template trussium "$chart" --namespace trussium-system >"$default_render"
helm template trussium "$chart" --namespace trussium-custom \
    --values "$custom_values" >"$custom_render"

if grep -Eq 'image: .*:(latest|main)$' "$default_render"; then
    echo "default chart values must use an immutable runtime image tag" >&2
    exit 1
fi

if grep -Eq '^kind: Secret$' "$default_render" "$custom_render"; then
    echo "the chart must reference existing Secrets, not render credentials" >&2
    exit 1
fi

if grep -Eiq \
    'grafana|loki|tempo|dashboard|^kind: (ServiceMonitor|PodMonitor|PrometheusRule)$' \
    "$default_render" "$custom_render"; then
    echo "observability backends and dashboards must remain operator-owned" >&2
    exit 1
fi

echo "Helm chart linting and rendering validation passed"
