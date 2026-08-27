# NetworkPolicy evaluation

The chart can optionally render a NetworkPolicy, disabled by default. The
runtime's network destinations are deployment-specific, so enabling the policy
requires explicit ingress peers and egress destinations.

## Traffic contract

| Direction | Traffic | Ownership |
| --- | --- | --- |
| Ingress | Client requests to the runtime Service on TCP 9000 | Operator selects clients and any ingress controller or gateway |
| Egress | Provider API requests and model metadata checks | Operator configures provider endpoints and allowed destinations |
| Egress | DNS lookups to the cluster DNS service | Cluster platform provides DNS and its service IP |
| Egress | OTLP HTTP traces when tracing is enabled | Operator supplies the collector endpoint and network path |
| Ingress | Kubernetes probes to `/health/*` | Chart configures probes; cluster networking must permit them |
| Ingress | Metrics scraping at `/metrics` when enabled | Operator-owned scraper and selection policy |

The chart cannot infer provider CIDRs, collector addresses, ingress identities,
DNS service IPs, or scraper namespaces. Provider credentials and endpoints also
remain outside the chart's ownership boundary.

## Minimum contract for a future opt-in policy

A policy is disabled by default and lets operators explicitly
provide:

- allowed ingress namespace and pod selectors;
- allowed egress CIDRs or named destinations for providers and collectors;
- the cluster DNS namespace/pod selector and port 53 UDP/TCP;
- an explicit metrics-scraper selector, if metrics ingress is restricted.

It renders only `networking.k8s.io/v1`, preserves the runtime Service and
probe paths, and include contract tests for disabled, ingress-only, and
fully-configured modes. It must not silently add `0.0.0.0/0` egress as a
security policy disguised as a default.

## Current recommendation

Enable the chart policy only when those selectors and destinations are known.
Teams with more complex requirements can still apply organization-owned
policies in their platform repository, using the traffic table above and
validating them against their provider and observability topology.
