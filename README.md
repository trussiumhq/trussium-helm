# Trussium Helm

<p align="center">
  <img src=".github/assets/trussium-logo.svg" alt="Trussium logo" width="144">
</p>

[![CI](https://github.com/trussiumhq/trussium-helm/actions/workflows/ci.yml/badge.svg)](https://github.com/trussiumhq/trussium-helm/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/trussiumhq/trussium-helm)](LICENSE)

The official, independently versioned Helm chart for deploying the
[Trussium](https://github.com/trussiumhq/trussium) AI runtime to Kubernetes.

The repository is named `trussium-helm`; the chart is named `trussium`. It
deploys and configures the runtime only. It does **not** install or manage the
future `trussium-operator`.

Optional platform integrations remain organization-owned by default; see the
roadmap and ADRs for the criteria required before a chart opt-in is introduced.

## What the chart installs

- A hardened, autoscaled Trussium Deployment.
- A ClusterIP Service on port 9000 by default.
- A ServiceAccount without API-token automounting.
- A ConfigMap containing non-secret runtime settings.
- An optional reference to an existing provider Secret.
- A PodDisruptionBudget and topology-spread constraints.
- An `autoscaling/v2` HorizontalPodAutoscaler with conservative production
  behavior.

No Namespace, provider credentials, registry credentials, Ingress, Grafana,
Prometheus, Loki, Tempo, collector, log agent, dashboard, alert, monitoring
custom resource, or operator resource is created.

## Prerequisites

- Kubernetes 1.25 or newer.
- Helm 3.12 or newer.
- A working Kubernetes Metrics API when default autoscaling is enabled,
  commonly provided by Metrics Server.
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
See the [compatibility policy and matrix](docs/COMPATIBILITY.md) for supported
chart/runtime combinations and upgrade ownership.
NetworkPolicy ownership and the requirements for a future opt-in policy are
documented in the [NetworkPolicy evaluation](docs/NETWORK_POLICY.md).
Ingress and certificate ownership are covered in the
[Ingress evaluation](docs/INGRESS.md).

## Compatibility

| Chart release | Default runtime | Kubernetes |
| --- | --- | --- |
| `0.6.x` | `0.67.x` | `>=1.25` |
| `0.5.x` | `0.41.x` | `>=1.25` |
| `0.4.9` | `0.40.x` | `>=1.25` |
| `0.4.8` | `0.39.x` | `>=1.25` |
| `0.4.7` | `0.38.x` | `>=1.25` |
| `0.4.6` | `0.37.x` | `>=1.25` |
| `0.4.5` | `0.36.x` | `>=1.25` |
| `0.4.4` | `0.35.x` | `>=1.25` |
| `0.4.3` | `0.34.x` | `>=1.25` |
| `0.4.2` | `0.33.x` | `>=1.25` |
| `0.4.1` | `0.32.x` | `>=1.25` |
| `0.4.0` | `0.31.x` | `>=1.25` |
| `0.3.4` | `0.30.x` | `>=1.25` |
| `0.3.3` | `0.29.x` | `>=1.25` |
| `0.3.2` | `0.28.x` | `>=1.25` |
| `0.3.1` | `0.27.x` | `>=1.25` |
| `0.3.0` | `0.26.x` | `>=1.25` |
| `0.2.x` | `0.25.x` | `>=1.25` |
| `0.1.x` | `0.24.x` | `>=1.25` |

Compatibility means the default runtime image and the chart deployment
contract are validated together. Overriding `image.tag` is supported, but the
operator owns compatibility validation for that combination.

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

## Dependency-aware readiness

Runtime v0.41.0 can make `/health/ready` reflect provider metadata access and,
optionally, the availability of a required model. The chart keeps these checks
disabled by default so installs without provider configuration retain the
existing `{"status":"ok"}` readiness response.

Enable the checks only after the referenced provider Secret and provider
endpoint are available:

```yaml
readiness:
  dependencyChecksEnabled: true
  dependencyTimeoutSeconds: 1
  dependencyCacheSeconds: 10
  requiredModel: gpt-4.1-mini
```

An empty `requiredModel` checks the provider's model-list metadata endpoint;
a non-empty value checks that exact model without performing inference. The
timeout bounds an individual provider check. Both successful and failed
results are cached for the configured window, and concurrent probes share one
in-flight check.

The `readiness` group controls runtime dependency policy. The separate
`readinessProbe` group controls Kubernetes probe timing and thresholds. Keep
the Kubernetes probe timeout long enough for the runtime dependency timeout,
allow for the configured failure threshold during provider incidents, and use
a staged rollout before enabling checks in production.

The chart renders only non-secret readiness settings. A required model is
visible to anyone who can read the ConfigMap, so do not put credentials,
provider endpoints, or other secrets in these values. The chart never creates
provider credentials, installs a provider or model server, downloads models,
or performs inference. See the version-pinned
[runtime health guide](https://github.com/trussiumhq/trussium/blob/v0.41.0/docs/HEALTH.md)
for response reasons, rollout guidance, privacy boundaries, and
troubleshooting.

## Configure

Inspect every default and its documentation:

```bash
helm show values oci://ghcr.io/trussiumhq/charts/trussium \
  --version CHART_VERSION
```

Common production overrides:

```yaml
autoscaling:
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 65

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

readiness:
  dependencyChecksEnabled: true
  dependencyTimeoutSeconds: 1
  dependencyCacheSeconds: 10
  requiredModel: gpt-4.1-mini

observability:
  tracing:
    enabled: true
    serviceName: trussium
    sampleRatio: 0.1
    otlpTracesEndpoint: http://otel-collector.observability.svc:4318/v1/traces
    otlpExportTimeoutSeconds: 5
```

The chart enables runtime metrics at `/metrics` and CPU-based horizontal
autoscaling by default. The HPA uses Kubernetes resource metrics; it does not
require Prometheus. To use a fixed replica count instead:

```yaml
autoscaling:
  enabled: false
replicaCount: 3
```

Do not manually scale the Deployment while the HPA is enabled. Tune the HPA
bounds and target instead. See the
[runtime metrics guide](https://github.com/trussiumhq/trussium/blob/main/docs/METRICS.md)
for the bounded Prometheus-compatible metric contract and optional custom
metrics extension point. The chart's ServiceMonitor ownership decision is
documented in [the ServiceMonitor evaluation](docs/SERVICEMONITOR.md).

OpenTelemetry tracing is disabled by default. The chart can render runtime
trace enablement, service name, parent-based sample ratio, OTLP HTTP/protobuf
traces endpoint, and export timeout, but it does not install a collector or
tracing backend. Supply a collector endpoint reachable from runtime pods and
choose sampling and retention policies appropriate to the cluster. Do not put
collector credentials in `extraConfig`; use an organization-managed network
or secret-based integration outside the chart.

Runtime v0.41.0 propagates W3C `traceparent` and optional `tracestate` from the
active provider span to supported OpenAI and Ollama-compatible JSON and SSE
requests. It does not propagate baggage, request IDs, arbitrary inbound
headers, prompts, completions, bodies, or credentials as tracing metadata. A
downstream provider or gateway must extract W3C Trace Context and create its
own span; the chart does not install or instrument that receiver. See the
[runtime tracing guide](https://github.com/trussiumhq/trussium/blob/main/docs/TRACING.md)
for the complete span, privacy, lifecycle, sampling, and propagation contract.

Runtime v0.41.0 also emits newline-delimited structured operational JSON for
safe configuration summaries, provider configuration readiness, application
and server lifecycle, graceful-drain outcomes, invalid configuration, and
trace-export failures. Provider configuration events describe local setup;
dependency readiness events separately describe the optional provider metadata
check and only affect `/health/ready` when checks are enabled.
The runtime excludes credentials, endpoints, payloads, raw settings, rejected
values, exception messages, and span data from these events. The chart relies
on the Kubernetes container log stream and does not install a collector,
shipper, storage backend, dashboard, or alert. See the
[runtime operational logging guide](https://github.com/trussiumhq/trussium/blob/main/docs/OPERATIONAL_LOGGING.md)
for the stable event and privacy contract.

Runtime v0.41.0 adds a public typed hierarchy for Trussium-owned
configuration, lifecycle, dependency, capability, and provider failures. This
is an additive application API: it does not change the chart, runtime settings,
HTTP or SSE error envelopes, cancellation, or Kubernetes behavior. See the
[runtime exception guide](https://github.com/trussiumhq/trussium/blob/v0.41.0/docs/ERRORS.md)
for stable codes, catch boundaries, compatibility, and privacy rules.

Runtime v0.41.0 adds a typed asynchronous lifecycle contract for
application-scoped runtime services with declaration-order startup,
reverse-order shutdown, partial-startup rollback, and bounded per-hook cleanup.
This is a runtime composition API: the chart does not declare services or
hooks, add a lifecycle value, or change pod termination behavior. Operators can
still pass advanced runtime environment settings through the existing
`extraConfig` map after their own compatibility review. See the version-pinned
[runtime lifecycle guide](https://github.com/trussiumhq/trussium/blob/v0.41.0/docs/LIFECYCLE.md)
for ordering, failure, cancellation, privacy, and extension boundaries.

Runtime v0.41.0 provides a public application-scoped service registry with
explicit insertion-ordered registration, stable optional and required lookup,
immutable discovery snapshots, duplicate protection, and one-way sealing
before lifecycle composition. This remains a runtime application API: the
chart does not declare or discover services, add registry values, load
plugins, or change lifecycle and pod behavior.
See the version-pinned
[runtime service registry guide](https://github.com/trussiumhq/trussium/blob/v0.41.0/docs/SERVICE_REGISTRY.md)
for registration, lookup, errors, ownership, privacy, and extension boundaries.

Runtime v0.41.0 lets registered application services opt into bounded component
health reporting. The runtime evaluates checks concurrently under independent
deadlines, preserves registry order, normalizes failures to stable reason
codes, emits transition-only structured events, and exposes the informational
`GET /health/components` endpoint. The endpoint always returns HTTP 200 and is
not a startup, liveness, or readiness probe. The chart keeps its existing
`/health/live` and `/health/ready` probes unchanged.

The default chart composition registers no application services, so the
component response is `{"status":"ok","components":[]}`. The chart does not
define component checks, health policy, recovery actions, service declarations,
or a dedicated component-health value. Advanced runtime compositions can pass
the bounded runtime timeout through the existing `extraConfig` map after their
own compatibility review. See the version-pinned
[runtime component health guide](https://github.com/trussiumhq/trussium/blob/v0.41.0/docs/COMPONENT_HEALTH.md)
for status, aggregation, deadline, event, privacy, and extension contracts.

Runtime v0.41.0 adds a provider-neutral application-scoped capability registry
with canonical names, explicit insertion-ordered registration, stable lookup,
immutable discovery snapshots, duplicate protection, safe errors, one-way
sealing, and application-owned execution composition. This is an additive
runtime Python API. The chart does not declare capabilities, add registry or
discovery values, expose an endpoint, load plugins, or change Kubernetes
resources, probes, settings, or provider behavior. The production runtime
registers configured chat execution internally under `chat.completions`. See
the version-pinned
[runtime capability registry guide](https://github.com/trussiumhq/trussium/blob/v0.41.0/docs/CAPABILITY_REGISTRY.md)
for identity, registration, lookup, sealing, ownership, compatibility, error,
privacy, and extension boundaries.

Runtime v0.41.0 adds frozen, bounded metadata to capability registrations and
an ordered `GET /v1/capabilities` discovery endpoint. Provider-free deployments
return `{"capabilities":[]}`. The response deliberately excludes provider,
model, implementation, health, availability, and configuration data. This
runtime-owned contract adds no chart values, templates, resources, probes, or
permissions. See the version-pinned
[runtime capability discovery guide](https://github.com/trussiumhq/trussium/blob/v0.41.0/docs/CAPABILITY_DISCOVERY.md)
for response shape, ordering, privacy, compatibility, and ownership boundaries.

Runtime v0.41.0 adds a sealed-registry-backed provider-neutral execution
pipeline for asynchronous and streaming capability work. It preserves context,
results, events, native failures, cancellation, and upstream cleanup while the
existing chat JSON/SSE telemetry and transport contracts remain unchanged. The
pipeline is runtime-owned and adds no chart value, template, resource, probe,
permission, endpoint, or configuration. See the version-pinned
[runtime capability execution pipeline guide](https://github.com/trussiumhq/trussium/blob/v0.41.0/docs/CAPABILITY_EXECUTION_PIPELINE.md)
for composition, invocation, cleanup, compatibility, and ownership boundaries.

Runtime v0.41.0 adds ordered provider-neutral capability middleware around the
execution pipeline. Application composition can observe immutable invocation
metadata, continue once, or short-circuit asynchronous and streaming work while
the runtime preserves context, failures, event identity, and deterministic
cleanup. Middleware remains runtime-owned and adds no chart value, template,
resource, probe, permission, endpoint, environment setting, or routing policy.
See the version-pinned
[runtime capability middleware guide](https://github.com/trussiumhq/trussium/blob/v0.41.0/docs/CAPABILITY_MIDDLEWARE.md)
for contracts, ordering, cleanup, compatibility, and ownership boundaries.

Runtime v0.41.0 lets registered capabilities optionally own application-scoped
resources through ordered asynchronous startup, reverse shutdown,
partial-startup rollback, bounded cleanup, deterministic state, and safe
operational failures. Ordinary capabilities remain unchanged. Lifecycle is a
runtime-owned Python contract and adds no chart value, schema, template,
resource, probe, permission, endpoint, environment setting, CRD, or operator
behavior. See the version-pinned
[runtime capability lifecycle guide](https://github.com/trussiumhq/trussium/blob/v0.41.0/docs/CAPABILITY_LIFECYCLE.md)
for ownership, ordering, cleanup, cancellation, errors, events, privacy, and
extension boundaries.

## Capability availability reporting

Runtime v0.41.0 gives every registered capability a bounded informational
availability state. Ordinary registrations default to available; optional
checks run concurrently under a runtime-owned deadline, preserve registry
order, normalize failures to stable reasons, and emit transition-only events.
The read-only `GET /v1/capabilities/availability` endpoint always returns HTTP
200 and is not a startup, liveness, or readiness probe.

The chart exposes only the positive per-check deadline:

```yaml
runtime:
  capabilityAvailabilityTimeoutSeconds: 1
```

This renders
`TRUSSIUM_RUNTIME__CAPABILITY_AVAILABILITY_TIMEOUT_SECONDS`. Changing it does
not gate execution or add routing, retry, fallback, recovery, capability
declarations, Kubernetes probes, resources, permissions, CRDs, or operator
behavior. The provider-free chart response is
`{"status":"available","capabilities":[]}`. See the version-pinned
[runtime capability availability guide](https://github.com/trussiumhq/trussium/blob/v0.41.0/docs/CAPABILITY_AVAILABILITY.md)
for values, aggregation, failures, events, privacy, and extension boundaries.

Runtime v0.41.0 provides three portable Grafana dashboard JSON models in the
runtime repository: a Prometheus overview, a Loki structured-log view, and a
Tempo trace investigation view. Prometheus is required only for the overview;
Loki and Tempo remain optional. The chart does not bundle, mount, import, or
provision those files and does not install Grafana, observability backends,
collectors, log agents, dashboard custom resources, or alerts. Operators own
data collection, dashboard import, backend access control, and retention. See
the [runtime dashboard guide](https://github.com/trussiumhq/trussium/blob/v0.41.0/docs/DASHBOARDS.md)
for artifacts, import methods, variables, privacy, and troubleshooting.

Runtime v0.41.0 also provides five portable Prometheus starter alerts for
missing telemetry, elevated request failures, elevated cancellations, high p95
latency, and process restarts. Their severity, hold times, traffic guards, and
thresholds are reference values that operators must review against their SLOs,
traffic, target-label topology, and maintenance model before paging.

The rules remain source-repository artifacts. This chart does not bundle or
load them and does not create a rule ConfigMap, `PrometheusRule`,
`AlertmanagerConfig`, notification route, silence, or monitoring backend.
Operators own rule loading, target scoping, threshold tuning, routing,
inhibition, maintenance windows, access control, and retention. See the
[runtime alerting guide](https://github.com/trussiumhq/trussium/blob/v0.41.0/docs/ALERTING.md)
and the
[reference rules](https://github.com/trussiumhq/trussium/blob/v0.41.0/deploy/observability/prometheus/rules/trussium-runtime-alerts.yaml)
for the complete contract and runbooks.

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

The repository uses Helm and portable shell tooling for chart validation. Python
is used only by the semantic-release packaging workflow.

```bash
scripts/helm-validate.sh
scripts/chart-contract-test.sh
scripts/chart-package.sh
```

The complete Kind lifecycle test builds runtime `v0.67.0` from a neighboring
checkout, installs pinned Metrics Server v0.8.1, and validates install, live
autoscaling, runtime metrics, tracing configuration, operational startup logs,
default component health, ordered capability discovery, empty capability
availability, dependency readiness, availability-timeout configuration,
upgrade and rollback, HTTP request correlation, fixed-scale upgrade,
autoscaling rollback, and uninstall:

```bash
TRUSSIUM_RUNTIME_SOURCE=../trussium scripts/chart-smoke-test.sh
```

See [CONTRIBUTING.md](CONTRIBUTING.md), [release operations](docs/RELEASES.md),
and the [roadmap](docs/ROADMAP.md).

## License

Apache License 2.0. See [LICENSE](LICENSE).
