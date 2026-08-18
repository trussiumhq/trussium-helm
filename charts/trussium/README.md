# Trussium chart

This application chart deploys the Trussium runtime. Chart releases are
versioned independently from runtime releases; `appVersion` identifies the
default compatible runtime image.

## Values

| Value | Default | Purpose |
| --- | --- | --- |
| `replicaCount` | `2` | Desired replicas when autoscaling is disabled. |
| `revisionHistoryLimit` | `3` | Retained Deployment revisions. |
| `image.repository` | `ghcr.io/trussiumhq/trussium` | Runtime image repository. |
| `image.tag` | `""` | Image tag; empty uses chart `appVersion`. |
| `image.pullPolicy` | `IfNotPresent` | Kubernetes image pull policy. |
| `imagePullSecrets` | `[{name: ghcr-credentials}]` | Existing registry Secrets. |
| `nameOverride` | `""` | Override the chart resource-name component. |
| `fullnameOverride` | `""` | Override complete resource names. |
| `serviceAccount.create` | `true` | Create a chart-owned ServiceAccount. |
| `serviceAccount.automount` | `false` | Automount the Kubernetes API token. |
| `serviceAccount.annotations` | `{}` | ServiceAccount annotations. |
| `serviceAccount.name` | `""` | Created or existing ServiceAccount name. |
| `podAnnotations` | `{}` | Additional pod annotations. |
| `podLabels` | `{}` | Additional non-selector pod labels. |
| `podSecurityContext` | hardened | Pod-level non-root and seccomp settings. |
| `securityContext` | hardened | Container filesystem, privilege, and capability settings. |
| `service.type` | `ClusterIP` | Kubernetes Service type. |
| `service.port` | `9000` | Service port. |
| `service.annotations` | `{}` | Service annotations. |
| `runtime.environment` | `production` | `TRUSSIUM_ENVIRONMENT`. |
| `runtime.host` | `0.0.0.0` | Runtime bind host. |
| `runtime.port` | `9000` | Container and runtime port. |
| `runtime.gracefulShutdownSeconds` | `30` | Active-workload drain deadline. |
| `timeouts.providerRequestSeconds` | `60` | Provider request deadline. |
| `timeouts.streamIdleSeconds` | `30` | Streaming event idle deadline. |
| `readiness.dependencyChecksEnabled` | `false` | Include provider metadata access in runtime readiness. |
| `readiness.dependencyTimeoutSeconds` | `1` | Positive deadline for one dependency check. |
| `readiness.dependencyCacheSeconds` | `10` | Positive success and failure cache window. |
| `readiness.requiredModel` | `""` | Exact model to require; empty lists provider models. |
| `observability.metrics.enabled` | `true` | Expose runtime metrics at `/metrics`. |
| `observability.tracing.enabled` | `false` | Enable runtime OpenTelemetry tracing and OTLP export. |
| `observability.tracing.serviceName` | `trussium` | OpenTelemetry `service.name`. |
| `observability.tracing.sampleRatio` | `1.0` | Parent-based root sampling probability from zero through one. |
| `observability.tracing.otlpTracesEndpoint` | `http://127.0.0.1:4318/v1/traces` | Full OTLP HTTP/protobuf traces endpoint. |
| `observability.tracing.otlpExportTimeoutSeconds` | `10` | Positive OTLP export request timeout. |
| `autoscaling.enabled` | `true` | Create the runtime HorizontalPodAutoscaler. |
| `autoscaling.minReplicas` | `2` | Autoscaling availability floor. |
| `autoscaling.maxReplicas` | `10` | Autoscaling replica ceiling. |
| `autoscaling.targetCPUUtilizationPercentage` | `70` | Named-container CPU target. |
| `autoscaling.behavior` | production defaults | Scale velocity and stabilization rules. |
| `providerSecret.name` | `trussium-provider` | Existing provider Secret; empty disables it. |
| `providerSecret.optional` | `true` | Allow startup when that Secret is absent. |
| `extraConfig` | `{}` | Additional non-secret ConfigMap entries. |
| `extraEnv` | `[]` | Additional container environment entries. |
| `extraEnvFrom` | `[]` | Additional container environment sources. |
| `startupProbe` | enabled | Startup probe timing and threshold. |
| `livenessProbe` | enabled | Liveness probe timing and threshold. |
| `readinessProbe` | enabled | Readiness probe timing and threshold. |
| `resources` | production defaults | CPU and memory requests and limits. |
| `deploymentStrategy` | zero unavailable | Deployment rollout strategy. |
| `podDisruptionBudget.enabled` | `true` | Create disruption protection. |
| `podDisruptionBudget.maxUnavailable` | `1` | Maximum voluntary unavailability. |
| `terminationGracePeriodSeconds` | `36` | Kubernetes termination window. |
| `topologySpreadConstraints` | hostname spread | Runtime placement across nodes. |
| `nodeSelector` | `{}` | Pod node selector. |
| `tolerations` | `[]` | Pod tolerations. |
| `affinity` | `{}` | Pod affinity rules. |
| `priorityClassName` | `""` | Existing PriorityClass name. |

The JSON Schema in the chart is authoritative for value types and constraints.

## Autoscaling and metrics

Default rendering omits Deployment `spec.replicas` so the
HorizontalPodAutoscaler owns scale. It targets the named `trussium` container,
can grow by at most 100% or four pods per minute, and uses a five-minute
scale-down stabilization window with a 25% or one-pod per-minute limit.

The default CPU signal requires Kubernetes Metrics API, commonly supplied by
Metrics Server. It does not require Prometheus. Disable autoscaling to restore
fixed `replicaCount` ownership:

```yaml
autoscaling:
  enabled: false
replicaCount: 3
```

Runtime metrics remain independently configurable through
`observability.metrics.enabled`. The chart does not install Prometheus,
Prometheus Adapter, ServiceMonitor, or other monitoring resources.

## Dependency-aware readiness

Runtime v0.38.0 can include provider metadata access in `/health/ready`. The
chart preserves backward-compatible behavior by disabling dependency checks by
default:

```yaml
readiness:
  dependencyChecksEnabled: true
  dependencyTimeoutSeconds: 1
  dependencyCacheSeconds: 10
  requiredModel: gpt-4.1-mini
```

When `requiredModel` is empty, the runtime lists provider models as a metadata
check. When it is non-empty, the runtime retrieves that exact model. Neither
path performs inference. The timeout bounds each check; successful and failed
results use the same cache window, and concurrent probes share one check.

The `readiness` group configures runtime dependency policy. `readinessProbe`
independently configures Kubernetes probe timing and failure thresholds. The
three base settings are always rendered in the non-secret ConfigMap;
`TRUSSIUM_READINESS__REQUIRED_MODEL` is omitted when no model is configured.

Before enabling checks, supply a valid existing provider Secret, verify network
access from runtime pods, and stage the rollout. The chart does not create
credentials, install providers or model servers, download models, or own
provider availability. The required-model identifier is non-secret ConfigMap
data visible to anyone who can read that resource; do not place credentials,
provider endpoints, or other secrets in readiness values. See the
version-pinned
[runtime health guide](https://github.com/trussiumhq/trussium/blob/v0.38.0/docs/HEALTH.md)
for response reasons, rollout guidance, privacy boundaries, and
troubleshooting.

## OpenTelemetry tracing

Tracing remains disabled by default because the chart does not install an
OpenTelemetry Collector or tracing backend. Enable it only after supplying an
endpoint reachable from the runtime pod network:

```yaml
observability:
  tracing:
    enabled: true
    serviceName: trussium
    sampleRatio: 0.1
    otlpTracesEndpoint: http://otel-collector.observability.svc:4318/v1/traces
    otlpExportTimeoutSeconds: 5
```

The settings are rendered into the non-secret ConfigMap. The schema requires a
non-blank service name, a sample ratio from `0` through `1`, an HTTP or HTTPS
endpoint, and a positive timeout. The loopback default points to the runtime
pod itself and is safe only while tracing is disabled or when a collector
sidecar intentionally listens there.

The chart does not accept OTLP credentials. Do not place authentication values
in `extraConfig`; integrate collector authentication through organization-owned
network and secret controls. The runtime excludes health and metrics traffic
and does not attach prompts, bodies, credentials, query strings, raw URLs, or
exception messages to spans.

With runtime v0.38.0, the active provider span is propagated to supported
OpenAI and Ollama-compatible JSON and SSE requests as W3C `traceparent` and
optional `tracestate`. Baggage, request IDs, arbitrary inbound headers,
payloads, and credentials remain behind the runtime privacy boundary. The
downstream provider or gateway owns W3C extraction and its receiver span; this
chart does not add downstream instrumentation or resources. See the
[runtime tracing guide](https://github.com/trussiumhq/trussium/blob/main/docs/TRACING.md)
for the complete contract.

## Structured operational logs

Runtime v0.38.0 writes bounded newline-delimited JSON events to standard
output for startup configuration, provider configuration readiness,
observability enablement, application and server shutdown, graceful-drain
timeouts, invalid settings, and trace-export failures.

`provider.configuration.ready` and `provider.configuration.unavailable`
describe whether the runtime constructed a provider capability from local
configuration. Separate `readiness.configuration.loaded` and dependency
transition events describe the optional metadata check without exposing raw
provider failures.

Operational events exclude credentials, provider and collector endpoints,
payloads, raw settings, rejected values, exception messages, and span data.
The chart does not add a collector, log shipper, backend, dashboard, alerting
rule, volume, sidecar, or new value for this contract. Kubernetes platform log
collection remains operator-owned. See the
[runtime operational logging guide](https://github.com/trussiumhq/trussium/blob/main/docs/OPERATIONAL_LOGGING.md)
for the stable event table and privacy boundary.

## Runtime exception hierarchy

Runtime v0.38.0 adds public typed bases for Trussium-owned configuration,
lifecycle, dependency, capability, and provider failures. This additive Python
API changes no chart values, templates, HTTP or SSE envelopes, cancellation,
or Kubernetes resources. See the version-pinned
[runtime exception guide](https://github.com/trussiumhq/trussium/blob/v0.38.0/docs/ERRORS.md)
for stable codes, catch boundaries, compatibility, and privacy rules.

## Runtime service lifecycle

Runtime v0.38.0 adds a typed asynchronous lifecycle contract for
application-scoped runtime services with declaration-order startup,
reverse-order shutdown, partial-startup rollback, and bounded per-hook cleanup.
This is runtime-owned composition behavior. The chart does not declare
services or hooks, add a dedicated cleanup value, or change pod termination
behavior. Operators may pass advanced runtime environment settings through the
existing `extraConfig` map after their own compatibility review. See the
version-pinned
[runtime lifecycle guide](https://github.com/trussiumhq/trussium/blob/v0.38.0/docs/LIFECYCLE.md)
for ordering, failure, cancellation, privacy, and extension boundaries.

## Runtime service registry

Runtime v0.38.0 provides a public application-scoped service registry with
explicit insertion-ordered registration, stable optional and required lookup,
immutable discovery snapshots, duplicate protection, and one-way sealing
before lifecycle composition. This is runtime-owned composition behavior. The
chart does not declare or discover services, add registry values, load
plugins, or change lifecycle and pod behavior.
See the version-pinned
[runtime service registry guide](https://github.com/trussiumhq/trussium/blob/v0.38.0/docs/SERVICE_REGISTRY.md)
for registration, lookup, errors, ownership, privacy, and extension boundaries.

## Runtime component health

Runtime v0.38.0 lets registered application services opt into bounded component
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
[runtime component health guide](https://github.com/trussiumhq/trussium/blob/v0.38.0/docs/COMPONENT_HEALTH.md)
for status, aggregation, deadline, event, privacy, and extension contracts.

## Core capability registry

Runtime v0.38.0 adds a provider-neutral application-scoped capability registry
with canonical names, explicit insertion-ordered registration, stable lookup,
immutable discovery snapshots, duplicate protection, safe errors, one-way
sealing, and application-owned execution composition. This is runtime-owned
Python behavior. The chart does not declare capabilities, add registry or
discovery values, expose an endpoint, load plugins, or change Kubernetes
resources, probes, settings, or provider behavior. The production runtime
registers configured chat execution internally under `chat.completions`. See
the version-pinned
[runtime capability registry guide](https://github.com/trussiumhq/trussium/blob/v0.38.0/docs/CAPABILITY_REGISTRY.md)
for identity, registration, lookup, sealing, ownership, compatibility, error,
privacy, and extension boundaries.

## Capability metadata and discovery

Runtime v0.38.0 adds frozen, bounded metadata to capability registrations and
an ordered `GET /v1/capabilities` discovery endpoint. Provider-free deployments
return `{"capabilities":[]}`. The response deliberately excludes provider,
model, implementation, health, availability, and configuration data. This is a
runtime-owned contract: the chart adds no values, templates, resources, probes,
or permissions. See the version-pinned
[runtime capability discovery guide](https://github.com/trussiumhq/trussium/blob/v0.38.0/docs/CAPABILITY_DISCOVERY.md)
for response shape, ordering, privacy, compatibility, and ownership boundaries.

## Capability execution pipeline

Runtime v0.38.0 adds a sealed-registry-backed provider-neutral execution
pipeline for asynchronous and streaming capability work. It preserves context,
results, events, native failures, cancellation, and upstream cleanup while the
existing chat JSON/SSE telemetry and transport contracts remain unchanged. The
pipeline is runtime-owned and adds no chart value, template, resource, probe,
permission, endpoint, or configuration. See the version-pinned
[runtime capability execution pipeline guide](https://github.com/trussiumhq/trussium/blob/v0.38.0/docs/CAPABILITY_EXECUTION_PIPELINE.md)
for composition, invocation, cleanup, compatibility, and ownership boundaries.

## Portable runtime dashboards

Runtime v0.38.0 provides three independently importable Grafana dashboard JSON
models in the runtime repository:

- `Trussium Runtime Overview` uses Prometheus for demand, active work,
  outcomes, latency, process health, and uptime.
- `Trussium Runtime Logs` uses Loki for configuration, lifecycle, execution,
  shutdown, and export events.
- `Trussium Runtime Traces` uses Tempo for recent, failed, slow, HTTP,
  capability, and provider trace searches.

Prometheus is required only for the overview. Loki and Tempo are optional. This
chart does not bundle, mount, import, or provision dashboard JSON and does not
install Grafana, any observability backend, a collector, log agent, dashboard
sidecar, custom resource, or alert. Collection, access control, retention, and
dashboard lifecycle remain operator-owned. See the
[runtime dashboard guide](https://github.com/trussiumhq/trussium/blob/v0.38.0/docs/DASHBOARDS.md)
for import, provisioning, variables, privacy, and troubleshooting.

## Portable runtime alerts

Runtime v0.38.0 provides five portable Prometheus starter alerts for missing
telemetry, elevated request failures, elevated cancellations, high p95 latency,
and process restarts. The published severities, hold times, traffic guards, and
thresholds are reference values that operators must tune for their SLOs,
traffic, target labels, and maintenance model before paging.

The rules remain source-repository artifacts. This chart does not bundle,
mount, or load them and does not create a rule ConfigMap, `PrometheusRule`,
`AlertmanagerConfig`, notification route, silence, or monitoring backend.
Operators own rule loading, target scoping, threshold tuning, routing,
inhibition, maintenance windows, access control, and retention. See the
[runtime alerting guide](https://github.com/trussiumhq/trussium/blob/v0.38.0/docs/ALERTING.md)
and the
[reference rules](https://github.com/trussiumhq/trussium/blob/v0.38.0/deploy/observability/prometheus/rules/trussium-runtime-alerts.yaml)
for the complete contract and runbooks.
