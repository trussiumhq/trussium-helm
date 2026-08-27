# ADR 0003: Defer chart-owned ServiceMonitor

- Status: Superseded by ADR 0006
- Date: 2026-08-27

## Context

ServiceMonitor is not a built-in Kubernetes resource; it is supplied by the
Prometheus Operator. Clusters differ in CRD installation, Prometheus selector
labels, namespace selection, scrape policy, and authorization requirements.

## Decision

Do not render a ServiceMonitor in the chart yet. Document the stable metrics
endpoint and require any future resource to be explicitly opt-in with
operator-supplied selector and scrape settings.

## Consequences

- Metrics remain available through the existing Service without new chart
  dependencies or CRDs.
- Platform teams can create a ServiceMonitor that matches their Prometheus
  deployment today.
- A future chart option must verify CRD/controller assumptions and preserve the
  current metrics-disabled behavior.
