# Trussium Helm

[![CI](https://github.com/trussiumhq/trussium-helm/actions/workflows/ci.yml/badge.svg)](https://github.com/trussiumhq/trussium-helm/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/trussiumhq/trussium-helm)](LICENSE)

The official, independently versioned Helm chart for deploying the
[Trussium](https://github.com/trussiumhq/trussium) AI runtime to Kubernetes.

The repository is named `trussium-helm`; the chart is named `trussium`. It
deploys and configures the runtime only. It does **not** install or manage the
future `trussium-operator`.

## What the chart installs

- A hardened, replicated Trussium Deployment.
- A ClusterIP Service on port 9000 by default.
- A ServiceAccount without API-token automounting.
- A ConfigMap containing non-secret runtime settings.
- An optional reference to an existing provider Secret.
- A PodDisruptionBudget and topology-spread constraints.

No Namespace, provider credentials, registry credentials, Ingress,
HorizontalPodAutoscaler, or monitoring custom resources are created.

## Prerequisites

- Kubernetes 1.25 or newer.
- Helm 3.12 or newer.
- Access to `ghcr.io/trussiumhq/trussium`.

The Trussium runtime package currently requires authenticated GHCR access.
Create the namespace and pull Secret without committing the token:

```bash
kubectl create namespace trussium-system
kubectl create secret docker-registry ghcr-credentials \
  --namespace trussium-system \
  --docker-server ghcr.io \
  --docker-username YOUR_GITHUB_USERNAME \
  --docker-password YOUR_GITHUB_TOKEN
```

Use a classic GitHub personal access token with `read:packages`. Prefer an
external secret manager for long-lived environments.

## Install

Authenticate to GHCR if the chart package is private, then install a released
chart from its OCI location:

```bash
helm registry login ghcr.io --username YOUR_GITHUB_USERNAME
helm install trussium \
  oci://ghcr.io/trussiumhq/charts/trussium \
  --version CHART_VERSION \
  --namespace trussium-system
```

The chart defaults to the compatible runtime release in `Chart.yaml`'s
`appVersion`. Chart and runtime versions are intentionally independent.

For a local checkout:

```bash
helm install trussium charts/trussium \
  --namespace trussium-system \
  --create-namespace
```

## Provider configuration

The chart references an optional existing Secret named `trussium-provider`.
For OpenAI:

```bash
kubectl create secret generic trussium-provider \
  --namespace trussium-system \
  --from-literal=TRUSSIUM_PROVIDER__NAME=openai \
  --from-literal=TRUSSIUM_PROVIDER__API_KEY=YOUR_PROVIDER_CREDENTIAL
```

For Ollama or another reachable OpenAI-compatible endpoint:

```bash
kubectl create secret generic trussium-provider \
  --namespace trussium-system \
  --from-literal=TRUSSIUM_PROVIDER__NAME=ollama \
  --from-literal=TRUSSIUM_PROVIDER__BASE_URL=http://ollama.ollama.svc:11434/v1
```

Reference a differently named Secret:

```yaml
providerSecret:
  name: organization-provider-secret
  optional: false
```

Set `providerSecret.name` to an empty string when no provider Secret should be
referenced. The chart never accepts or renders credential values.

## Configure

Inspect every default and its documentation:

```bash
helm show values oci://ghcr.io/trussiumhq/charts/trussium \
  --version CHART_VERSION
```

Common production overrides:

```yaml
replicaCount: 3

imagePullSecrets:
  - name: organization-ghcr-credentials

resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: "2"
    memory: 1Gi

timeouts:
  providerRequestSeconds: 90
  streamIdleSeconds: 45
```

The complete value reference is in the
[chart README](charts/trussium/README.md). `values.schema.json` rejects unknown
or invalid top-level settings before resources are installed.

If `runtime.gracefulShutdownSeconds` changes, keep
`terminationGracePeriodSeconds` at least six seconds longer so cancellation
cleanup and the Kubernetes operational margin remain bounded.

## Upgrade and rollback

Review the rendered change before upgrading:

```bash
helm diff upgrade trussium \
  oci://ghcr.io/trussiumhq/charts/trussium \
  --version NEW_CHART_VERSION \
  --namespace trussium-system

helm upgrade trussium \
  oci://ghcr.io/trussiumhq/charts/trussium \
  --version NEW_CHART_VERSION \
  --namespace trussium-system \
  --wait
```

The optional `helm diff` command requires the community Helm Diff plugin.
Rollback retains prior Helm release values and manifests:

```bash
helm history trussium --namespace trussium-system
helm rollback trussium REVISION --namespace trussium-system --wait
```

## Remove

```bash
helm uninstall trussium --namespace trussium-system --wait
```

Helm removes chart-owned resources but deliberately leaves the Namespace and
externally managed Secrets in place.

## Development

The repository uses Python 3.12+, uv, Ruff, strict MyPy, Pytest, and Helm.

```bash
uv sync
uv run ruff check .
uv run ruff format --check .
uv run mypy tests
uv run pytest
scripts/helm-validate.sh
scripts/chart-package.sh
```

The complete Kind lifecycle test builds runtime `v0.24.0` from a neighboring
checkout and validates install, readiness, HTTP request correlation, upgrade,
rollback, and uninstall:

```bash
TRUSSIUM_RUNTIME_SOURCE=../trussium scripts/chart-smoke-test.sh
```

See [CONTRIBUTING.md](CONTRIBUTING.md), [release operations](docs/RELEASES.md),
and the [roadmap](docs/ROADMAP.md).

## License

Apache License 2.0. See [LICENSE](LICENSE).
