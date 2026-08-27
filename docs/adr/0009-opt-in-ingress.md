# ADR 0009: Provide an opt-in Ingress

- Status: Accepted
- Date: 2026-08-27

## Context

The chart has a stable Service backend, but Ingress controllers, hostnames,
authentication, DNS, and TLS automation remain cluster-specific.

## Decision

Render `networking.k8s.io/v1` Ingress only when `ingress.enabled` is true.
Require explicit class, hosts, paths, annotations, and existing TLS Secret
references. Do not install controllers, certificates, DNS, authentication, or
public load balancers.

## Consequences

- Existing internal deployments remain unchanged.
- Operators can compose approved routing around the chart Service.
- IngressClass, controller, TLS, and exposure lifecycle remain organization-owned.
