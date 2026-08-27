# ServiceMonitor evaluation

The chart exposes runtime metrics and can optionally render a `ServiceMonitor`.
The option is disabled by default because ServiceMonitor is a Prometheus
Operator custom resource; enabling it requires the CRD and controller to exist.

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

A chart option is disabled by default and requires an installed Prometheus
Operator. Operators can provide the ServiceMonitor
namespace, labels used by their Prometheus selector, scrape interval, timeout,
and optional TLS or authorization settings. The chart must not guess those
values or create Prometheus, RBAC, dashboards, alerts, or monitoring backends.

The option renders only when metrics are enabled and includes contract
tests for disabled, default opt-in, and custom-selector modes. Kind validation
should remain provider-free and should not assume a Prometheus Operator is
installed.

## Current recommendation

Enable the chart option when the Prometheus Operator and its selector policy are
known. Select the chart Service by its stable `app.kubernetes.io/name:
trussium` and `app.kubernetes.io/instance` labels, target port `http`, and path
`/metrics`.
