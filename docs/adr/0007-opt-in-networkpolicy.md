# ADR 0007: Provide an opt-in NetworkPolicy

- Status: Accepted
- Date: 2026-08-27

## Context

Network destinations and ingress peers are deployment-specific, but a stable
policy shape can still support explicit operator configuration.

## Decision

Render `networking.k8s.io/v1` NetworkPolicy only when
`networkPolicy.enabled` is true. Require operators to provide ingress peers,
provider/collector egress peers and ports, and DNS peers as needed. Keep the
default disabled and do not guess CIDRs, selectors, or CNI behavior.

## Consequences

- Existing installations remain unchanged.
- Enabling the option can intentionally create deny-by-default behavior when
  peers are omitted, so operators must configure and test it carefully.
- Provider, DNS, CNI, and cluster policy ownership remains with operators.
