#!/bin/sh

set -eu

repository_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
chart="$repository_root/charts/trussium"
custom_values="$repository_root/tests/fixtures/custom-values.yaml"
default_render="$(mktemp)"
custom_render="$(mktemp)"
error_output="$(mktemp)"

cleanup() {
    rm -f "$default_render" "$custom_render" "$error_output"
}
trap cleanup EXIT INT TERM

fail() {
    echo "chart contract failure: $*" >&2
    exit 1
}

assert_equal() {
    actual="$1"
    expected="$2"
    description="$3"
    [ "$actual" = "$expected" ] || fail "$description: expected '$expected', got '$actual'"
}

assert_contains() {
    needle="$1"
    file="$2"
    description="$3"
    grep -Fq "$needle" "$file" || fail "$description: missing '$needle'"
}

assert_not_contains() {
    needle="$1"
    file="$2"
    description="$3"
    if grep -Fq "$needle" "$file"; then
        fail "$description: found '$needle'"
    fi
}

expect_template_failure() {
    description="$1"
    shift
    if helm template trussium "$chart" "$@" > /dev/null 2>"$error_output"; then
        fail "$description: template unexpectedly succeeded"
    fi
}

command -v helm >/dev/null 2>&1 || fail "helm is required"
command -v yq >/dev/null 2>&1 || fail "yq is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"

helm lint --strict "$chart"
helm lint --strict "$chart" --values "$custom_values"
helm template trussium "$chart" --namespace trussium-system >"$default_render"
helm template trussium "$chart" --namespace trussium-custom \
    --values "$custom_values" >"$custom_render"

assert_equal "$(yq -r 'select(.kind == "Deployment") | .metadata.name' "$default_render")" \
    "trussium" "default deployment name"
assert_equal "$(yq -r 'select(.kind == "Deployment") | .spec.revisionHistoryLimit' "$default_render")" \
    "3" "revision history limit"
assert_equal "$(yq -r 'select(.kind == "Deployment") | .spec.template.spec.securityContext.runAsUser' "$default_render")" \
    "10001" "runtime UID"
assert_equal "$(yq -r 'select(.kind == "Deployment") | .spec.template.spec.securityContext.runAsGroup' "$default_render")" \
    "10001" "runtime GID"
assert_equal "$(yq -r 'select(.kind == "Deployment") | .spec.template.spec.securityContext.seccompProfile.type' "$default_render")" \
    "RuntimeDefault" "seccomp profile"
assert_equal "$(yq -r 'select(.kind == "Deployment") | .spec.template.spec.containers[0].image' "$default_render")" \
    "ghcr.io/trussiumhq/trussium:0.41.0" "default runtime image"
assert_equal "$(yq -r 'select(.kind == "Deployment") | .spec.template.spec.containers[0].ports[0].containerPort' "$default_render")" \
    "9000" "runtime port"
assert_equal "$(yq -r 'select(.kind == "Deployment") | .spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem' "$default_render")" \
    "true" "read-only root filesystem"
assert_equal "$(yq -r 'select(.kind == "Deployment") | .spec.template.spec.containers[0].securityContext.capabilities.drop[0]' "$default_render")" \
    "ALL" "dropped capabilities"
assert_equal "$(yq -r 'select(.kind == "Deployment") | .spec.template.spec.containers[0].readinessProbe.httpGet.path' "$default_render")" \
    "/health/ready" "readiness probe"
assert_equal "$(yq -r 'select(.kind == "Deployment") | .spec.template.spec.containers[0].livenessProbe.httpGet.path' "$default_render")" \
    "/health/live" "liveness probe"
assert_equal "$(yq -r 'select(.kind == "Service") | .spec.ports[0].port' "$default_render")" \
    "9000" "service port"
assert_equal "$(yq -r 'select(.kind == "Service") | .spec.ports[0].targetPort' "$default_render")" \
    "http" "service target port"
assert_equal "$(yq -r 'select(.kind == "HorizontalPodAutoscaler") | .spec.minReplicas' "$default_render")" \
    "2" "minimum autoscaler replicas"
assert_equal "$(yq -r 'select(.kind == "HorizontalPodAutoscaler") | .spec.maxReplicas' "$default_render")" \
    "10" "maximum autoscaler replicas"
assert_equal "$(yq -r 'select(.kind == "ConfigMap") | .data.TRUSSIUM_RUNTIME__CAPABILITY_AVAILABILITY_TIMEOUT_SECONDS' "$default_render")" \
    "1" "capability availability timeout"
assert_equal "$(yq -r 'select(.kind == "ConfigMap") | .data.TRUSSIUM_READINESS__DEPENDENCY_CHECKS_ENABLED' "$default_render")" \
    "false" "readiness disabled by default"
assert_equal "$(yq -r 'select(.kind == "ConfigMap") | .data.TRUSSIUM_OBSERVABILITY__METRICS_ENABLED' "$default_render")" \
    "true" "metrics enabled"
assert_equal "$(yq -r 'select(.kind == "ConfigMap") | .data.TRUSSIUM_OBSERVABILITY__TRACING_ENABLED' "$default_render")" \
    "false" "tracing disabled by default"

assert_equal "$(yq -r 'select(.kind == "Deployment") | .spec.replicas' "$custom_render")" \
    "3" "custom replica count"
assert_equal "$(yq -r 'select(.kind == "Service") | .spec.type' "$custom_render")" \
    "LoadBalancer" "custom service type"
assert_equal "$(yq -r 'select(.kind == "Service") | .spec.ports[0].port' "$custom_render")" \
    "8080" "custom service port"
assert_equal "$(yq -r 'select(.kind == "Deployment") | .spec.template.spec.serviceAccountName' "$custom_render")" \
    "trussium-existing" "custom service account"
assert_equal "$(yq -r 'select(.kind == "ConfigMap") | .data.TRUSSIUM_READINESS__DEPENDENCY_CHECKS_ENABLED' "$custom_render")" \
    "true" "custom readiness enablement"
assert_equal "$(yq -r 'select(.kind == "ConfigMap") | .data.TRUSSIUM_OBSERVABILITY__TRACING_ENABLED' "$custom_render")" \
    "true" "custom tracing enablement"

assert_not_contains "kind: Secret" "$default_render" "default credential rendering"
assert_not_contains "API_KEY" "$default_render" "credential key rendering"
assert_not_contains "grafana" "$default_render" "Grafana rendering"
assert_not_contains "loki" "$default_render" "Loki rendering"
assert_not_contains "tempo" "$default_render" "Tempo rendering"
assert_not_contains "alertmanager" "$default_render" "Alertmanager rendering"
assert_not_contains "ServiceMonitor" "$default_render" "ServiceMonitor rendering"
assert_not_contains "PrometheusRule" "$default_render" "PrometheusRule rendering"

expect_template_failure "replicaCount schema" --set replicaCount=0
assert_contains "replicaCount" "$error_output" "replicaCount error"
expect_template_failure "autoscaling target schema" \
    --set autoscaling.targetCPUUtilizationPercentage=0
assert_contains "targetCPUUtilizationPercentage" "$error_output" "autoscaling target error"
expect_template_failure "unknown tracing value" --set observability.tracing.unexpected=true
assert_contains "Additional property" "$error_output" "unknown tracing error"
expect_template_failure "unknown readiness value" --set readiness.unexpected=true
assert_contains "Additional property" "$error_output" "unknown readiness error"
expect_template_failure "unknown runtime value" --set runtime.unexpected=true
assert_contains "Additional property" "$error_output" "unknown runtime error"
expect_template_failure "invalid capability deadline" \
    --set runtime.capabilityAvailabilityTimeoutSeconds=0
assert_contains "capabilityAvailabilityTimeoutSeconds" "$error_output" "capability deadline error"
expect_template_failure "invalid readiness timeout" --set readiness.dependencyTimeoutSeconds=0
assert_contains "dependencyTimeoutSeconds" "$error_output" "readiness timeout error"
expect_template_failure "invalid tracing endpoint" \
    --set-string observability.tracing.otlpTracesEndpoint=grpc://collector:4317
assert_contains "otlpTracesEndpoint" "$error_output" "tracing endpoint error"
expect_template_failure "inverted autoscaling bounds" --set autoscaling.minReplicas=11
assert_contains "autoscaling.minReplicas must be less than or equal" "$error_output" "autoscaling bounds error"

helm template trussium "$chart" --set deploymentStrategy.type=Recreate >"$default_render"
assert_equal "$(yq -r 'select(.kind == "Deployment") | .spec.strategy | tojson' "$default_render" | jq -c .)" \
    '{"type":"Recreate"}' "recreate deployment strategy"

echo "Helm chart contract tests passed"
