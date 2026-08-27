# ADR 0006: Provide an opt-in ServiceMonitor

- Status: Accepted
- Date: 2026-08-27

## Context

The chart has a stable Prometheus-compatible metrics endpoint and named
Service port. Operators requested a convenient ServiceMonitor, but clusters
vary in Prometheus Operator installation and selector policy.

## Decision

Render `monitoring.coreos.com/v1` ServiceMonitor only when both
`observability.metrics.enabled` and `observability.serviceMonitor.enabled` are
true. Expose explicit namespace, labels, annotations, interval, timeout, and
path values; keep the option disabled by default and do not install the CRD or
controller.

## Consequences

- Existing installations and non-Prometheus clusters are unchanged.
- Operators can opt in without maintaining a duplicate resource.
- The Prometheus Operator remains a prerequisite and its lifecycle remains
  organization-owned.
