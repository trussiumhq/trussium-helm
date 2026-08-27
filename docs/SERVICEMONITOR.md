# ServiceMonitor evaluation

The chart exposes runtime metrics but does not render a `ServiceMonitor`. A
ServiceMonitor is a Prometheus Operator custom resource, so rendering one
without confirming that the CRD and controller exist would make otherwise
valid Helm installs fail or leave a misleading, unscheduled object.

## Scraping contract

| Field | Contract |
| --- | --- |
| Service port | Named `http`, default service port `9000` |
| Metrics path | `/metrics` |
| Enablement | `observability.metrics.enabled: true` (default) |
| Protocol | Prometheus text exposition over HTTP |
| Target | The chart-owned `trussium` Service selecting runtime pods |

The runtime metrics endpoint is independent from the HPA: autoscaling uses
Kubernetes resource metrics and does not require Prometheus.

## Minimum contract for a future opt-in resource

A future chart option must be disabled by default and require an installed
Prometheus Operator. Operators must be able to provide the ServiceMonitor
namespace, labels used by their Prometheus selector, scrape interval, timeout,
and optional TLS or authorization settings. The chart must not guess those
values or create Prometheus, RBAC, dashboards, alerts, or monitoring backends.

The option must render only when metrics are enabled and must include contract
tests for disabled, default opt-in, and custom-selector modes. Kind validation
should remain provider-free and should not assume a Prometheus Operator is
installed.

## Current recommendation

Use an organization-owned ServiceMonitor in the platform repository when the
Prometheus Operator is available. Select the chart Service by its stable
`app.kubernetes.io/name: trussium` and `app.kubernetes.io/instance` labels,
target port `http`, and path `/metrics`.
