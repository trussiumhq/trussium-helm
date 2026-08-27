# ADR 0002: Defer chart-owned NetworkPolicy

- Status: Superseded by ADR 0007
- Date: 2026-08-27

## Context

Trussium pods accept operator-selected clients and call operator-selected
providers and optional telemetry collectors. Kubernetes NetworkPolicy rules
are namespace- and selector-specific, while the chart cannot discover those
deployment choices or provider network ranges.

## Decision

Do not render a NetworkPolicy in the chart yet. Document the traffic contract
and require any future policy to be explicitly opt-in with operator-supplied
selectors and destinations.

## Consequences

- Existing deployments retain their current connectivity and behavior.
- Platform teams can apply organization-owned deny policies immediately.
- A future chart policy must define DNS, provider, collector, probe, and metrics
  paths before it can be enabled safely.
- The chart does not provide a false sense of egress restriction through broad
  or guessed CIDR defaults.
