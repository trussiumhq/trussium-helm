#!/bin/sh

set -eu

repository_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
runtime_source="${TRUSSIUM_RUNTIME_SOURCE:-$repository_root/../trussium}"
cluster="${TRUSSIUM_KIND_CLUSTER:-trussium-helm-smoke-$$}"
context="kind-$cluster"
namespace="trussium-helm-smoke"
release="trussium"
image="${TRUSSIUM_HELM_IMAGE:-trussium:helm-smoke}"
values="$(mktemp)"
headers="$(mktemp)"
body="$(mktemp)"
port_forward_log="$(mktemp)"
created_cluster=false
port_forward_pid=""

cleanup() {
    if [ -n "$port_forward_pid" ]; then
        kill "$port_forward_pid" >/dev/null 2>&1 || true
        wait "$port_forward_pid" >/dev/null 2>&1 || true
    fi

    helm --kube-context "$context" uninstall "$release" --namespace "$namespace" \
        >/dev/null 2>&1 || true
    kubectl --context "$context" delete namespace "$namespace" --wait=false \
        >/dev/null 2>&1 || true

    if [ "$created_cluster" = true ]; then
        kind delete cluster --name "$cluster" >/dev/null 2>&1 || true
    fi

    rm -f "$values" "$headers" "$body" "$port_forward_log"
}

trap cleanup EXIT INT TERM

assert_equal() {
    actual="$1"
    expected="$2"
    description="$3"

    if [ "$actual" != "$expected" ]; then
        echo "$description: expected '$expected', got '$actual'" >&2
        exit 1
    fi
}

for command_name in docker kind kubectl helm curl python3; do
    command -v "$command_name" >/dev/null 2>&1 || {
        echo "$command_name is required for the Helm smoke test" >&2
        exit 1
    }
done

if [ ! -f "$runtime_source/Dockerfile" ]; then
    echo "TRUSSIUM_RUNTIME_SOURCE must point to a Trussium runtime checkout" >&2
    exit 1
fi

if ! kind get clusters | grep -Fx "$cluster" >/dev/null 2>&1; then
    kind create cluster --name "$cluster" --wait 90s
    created_cluster=true
fi

docker build --quiet --tag "$image" "$runtime_source"
kind load docker-image "$image" --name "$cluster"

cat >"$values" <<EOF
image:
  repository: ${image%:*}
  tag: "${image##*:}"
  pullPolicy: Never
imagePullSecrets: []
providerSecret:
  name: ""
EOF

"$repository_root/scripts/helm-validate.sh"
helm --kube-context "$context" install "$release" "$repository_root/charts/trussium" \
    --namespace "$namespace" --create-namespace --values "$values" --wait --timeout 180s
kubectl --context "$context" --namespace "$namespace" rollout status deployment/trussium \
    --timeout=180s

assert_equal "$(kubectl --context "$context" --namespace "$namespace" get deployment trussium \
    -o jsonpath='{.status.readyReplicas}')" "2" "ready replicas after install"
assert_equal "$(kubectl --context "$context" --namespace "$namespace" get deployment trussium \
    -o jsonpath='{.spec.template.spec.securityContext.runAsUser}')" "10001" "runtime UID"
assert_equal "$(kubectl --context "$context" --namespace "$namespace" get deployment trussium \
    -o jsonpath='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}')" \
    "true" "read-only root filesystem"
assert_equal "$(kubectl --context "$context" --namespace "$namespace" get poddisruptionbudget trussium \
    -o jsonpath='{.spec.maxUnavailable}')" "1" "maximum unavailable pods"

port="$(python3 -c 'import socket; sock = socket.socket(); sock.bind(("127.0.0.1", 0)); print(sock.getsockname()[1]); sock.close()')"
kubectl --context "$context" --namespace "$namespace" port-forward service/trussium \
    "$port:9000" >"$port_forward_log" 2>&1 &
port_forward_pid=$!

attempt=0
until curl --fail --silent "http://127.0.0.1:$port/health/live" >/dev/null 2>&1; do
    if ! kill -0 "$port_forward_pid" >/dev/null 2>&1; then
        cat "$port_forward_log" >&2
        echo "Helm smoke-test port-forward exited before Trussium became reachable" >&2
        exit 1
    fi

    attempt=$((attempt + 1))
    if [ "$attempt" -ge 60 ]; then
        kubectl --context "$context" --namespace "$namespace" get pods >&2
        kubectl --context "$context" --namespace "$namespace" logs \
            -l app.kubernetes.io/name=trussium --tail=100 >&2
        exit 1
    fi
    sleep 1
done

curl --fail --silent --show-error "http://127.0.0.1:$port/health/ready" \
    --header "X-Request-ID: helm-smoke-1" --dump-header "$headers" --output "$body"
assert_equal "$(cat "$body")" '{"status":"ok"}' "readiness response"
request_id="$(awk 'tolower($1) == "x-request-id:" {gsub("\r", "", $2); print $2}' "$headers")"
assert_equal "$request_id" "helm-smoke-1" "request correlation header"

kill "$port_forward_pid" >/dev/null 2>&1 || true
wait "$port_forward_pid" >/dev/null 2>&1 || true
port_forward_pid=""

helm --kube-context "$context" upgrade "$release" "$repository_root/charts/trussium" \
    --namespace "$namespace" --values "$values" --set replicaCount=3 --wait --timeout 180s
assert_equal "$(kubectl --context "$context" --namespace "$namespace" get deployment trussium \
    -o jsonpath='{.status.readyReplicas}')" "3" "ready replicas after upgrade"

helm --kube-context "$context" rollback "$release" 1 --namespace "$namespace" --wait --timeout 180s
assert_equal "$(kubectl --context "$context" --namespace "$namespace" get deployment trussium \
    -o jsonpath='{.status.readyReplicas}')" "2" "ready replicas after rollback"

helm --kube-context "$context" uninstall "$release" --namespace "$namespace" --wait
if kubectl --context "$context" --namespace "$namespace" get deployment trussium >/dev/null 2>&1; then
    echo "Trussium Deployment remained after Helm uninstall" >&2
    exit 1
fi

echo "Helm install, health, upgrade, rollback, and uninstall validation passed"
