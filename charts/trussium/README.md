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
exception messages to spans. See the
[runtime tracing guide](https://github.com/trussiumhq/trussium/blob/main/docs/TRACING.md)
for the complete contract.
