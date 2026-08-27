# ADR 0004: Defer chart-owned Ingress

- Status: Accepted
- Date: 2026-08-27

## Context

Ingress is implemented by cluster-specific controllers and is commonly coupled
to DNS, TLS automation, authentication, and public exposure policy. The chart
cannot safely infer those choices.

## Decision

Do not render an Ingress in the chart yet. Document the Service routing contract
and require any future resource to be explicitly opt-in with operator-provided
class, host, path, and existing TLS Secret settings.

## Consequences

- Default installations remain internal and are not exposed accidentally.
- Platform teams can compose their approved ingress and authentication stack
  around the stable Service today.
- A future chart option must avoid owning certificate issuance, DNS, controllers,
  authentication, or public load-balancer lifecycle.
