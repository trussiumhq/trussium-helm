# Trussium chart

This application chart deploys the Trussium runtime. Chart releases are
versioned independently from runtime releases; `appVersion` identifies the
default compatible runtime image.

## Values

| Value | Default | Purpose |
| --- | --- | --- |
| `replicaCount` | `2` | Desired runtime replicas. |
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
