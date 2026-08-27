# Ingress evaluation

The chart does not render an Ingress today. Ingress resources depend on a
cluster's controller, class, hostname, authentication gateway, and certificate
management policy. A default chart Ingress could expose the runtime or conflict
with an existing routing layer.

## Routing contract

| Field | Contract |
| --- | --- |
| Backend | Chart-owned `trussium` Service |
| Backend port | Service port name `http` (9000 by default) |
| Runtime paths | `/` and the runtime's HTTP API paths, including `/health/*` and `/metrics` when enabled |
| Controller | Operator-selected `IngressClass` and controller implementation |
| Hostnames | Operator-owned DNS names and routing policy |
| TLS | Existing Secret or organization-owned certificate automation |

The runtime does not require an Ingress for in-cluster use. A ClusterIP Service
and port-forward remain the default access paths. External exposure should be
introduced only after authentication, rate limiting, request-size limits,
timeouts, and observability requirements are defined.

## Minimum contract for a future opt-in resource

A future chart option must be disabled by default and require explicit:

- `ingressClassName`, hostnames, and paths;
- an existing TLS Secret reference, without rendering certificate material;
- controller-specific annotations supplied by the operator;
- whether health and metrics paths are exposed externally.

The option must render `networking.k8s.io/v1` only, target the named `http`
Service port, and include tests for disabled, HTTP, and TLS configurations. It
must not install an ingress controller, Certificate or Issuer resources,
authentication gateway, DNS record, or public load balancer.

## Current recommendation

Use an organization-owned Ingress in the platform repository, fronted by the
approved controller and authentication layer. Keep `/health/*` and `/metrics`
internal unless the platform explicitly needs external access.
