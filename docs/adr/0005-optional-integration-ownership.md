# ADR 0005: Organization-owned optional platform integrations

- Status: Accepted
- Date: 2026-08-27

## Context

NetworkPolicy, ServiceMonitor, and Ingress depend on cluster-specific network,
Prometheus Operator, routing, authentication, DNS, and certificate choices.
The chart has evaluated each contract without rendering those resources.

## Decision

Keep these integrations organization-owned by default. A chart opt-in is only
appropriate when the contract is stable, values are explicit, the default is
disabled, render tests cover enabled and disabled modes, and live validation is
available for any controller or CRD dependency.

## Consequences

- The runtime chart remains portable across Kubernetes distributions.
- Platform teams retain control of exposure, scraping, network restrictions,
  authentication, and certificate lifecycle.
- Future opt-ins must justify their dependency and operational ownership in a
  separate design and compatibility review.
