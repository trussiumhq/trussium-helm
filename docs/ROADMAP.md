# Roadmap

_Last updated: August 2026_

This repository owns the independently versioned Helm distribution for the
Trussium runtime. Runtime code and static Kustomize manifests remain in
[`trussium`](https://github.com/trussiumhq/trussium); the future operator
remains a separate project.

## Current focus

The production Helm chart now carries the validated Trussium v0.67.0
Kubernetes contract into an independently released distribution:

- Hardened autoscaled runtime pods with a two-replica availability floor.
- Configurable non-secret runtime settings and existing Secret integration.
- Private-registry authentication, health probes, resource boundaries,
  topology spreading, zero-unavailable rolling updates, disruption protection,
  and bounded graceful shutdown.
- Schema-validated values and deterministic render tests.
- A real Kind lifecycle test covering install, health, upgrade, rollback, and
  uninstall.
- Independent Conventional Commit releases with GitHub and OCI artifacts.
- Prometheus-compatible runtime metrics enabled by default.
- Configurable `autoscaling/v2` HorizontalPodAutoscaler using the named
  runtime container's CPU resource metric.
- Fixed-replica fallback when autoscaling is disabled.
- Pinned Metrics Server Kind validation covering live HPA activation, upgrade,
  rollback, and removal.
- OpenTelemetry tracing values for enablement, service identity, parent-based
  sampling, OTLP HTTP/protobuf endpoint, and export timeout.
- Tracing-disabled defaults until an operator supplies a reachable collector
  with an intentional sampling and retention policy.
- Schema, render, package, and Kind upgrade/rollback validation for the full
  tracing configuration contract without chart-owned collector resources.
- Runtime v0.41.0 outbound W3C `traceparent` and optional `tracestate`
  propagation through the existing tracing configuration contract.
- Explicit runtime privacy boundaries for baggage, request IDs, arbitrary
  headers, payloads, and credentials, without chart-owned receiver resources.
- Runtime v0.41.0 structured operational events for configuration, provider
  readiness, lifecycle, graceful drain, and trace-export failures.
- Default-deployment validation of safe startup events from live pod logs.
- Explicit operational-log privacy boundaries without chart-owned collectors,
  shippers, storage backends, dashboards, alerts, sidecars, or volumes.
- Runtime v0.41.0 portable Prometheus, Loki, and Tempo dashboard artifacts with
  stable identities and selectable operator-owned data sources.
- Explicit dashboard ownership boundaries without chart-bundled JSON,
  ConfigMaps, sidecars, custom resources, monitoring backends, or alerts.
- Version-pinned dashboard import, collection, privacy, and troubleshooting
  guidance linked from chart operations documentation.
- Runtime v0.41.0 portable Prometheus starter alerts and operator runbooks for
  missing telemetry, request failures, cancellations, latency, and restarts.
- Explicit alerting ownership boundaries without chart-bundled rules,
  ConfigMaps, `PrometheusRule`, `AlertmanagerConfig`, notification routing, or
  monitoring backends.
- Version-pinned alert adoption, tuning, routing, lifecycle, privacy, and
  troubleshooting guidance linked from chart operations documentation.
- Runtime v0.41.0 dependency-aware readiness settings for opt-in provider
  metadata and required-model checks, with bounded timeout and cache controls.
- Backward-compatible disabled defaults, conditional required-model rendering,
  strict value validation, and live install/upgrade/rollback coverage.
- Version-pinned health, rollout, privacy, ownership, and troubleshooting
  guidance without chart-managed credentials, providers, or model servers.
- Runtime v0.41.0 public exception hierarchy compatibility guidance without new
  chart values, templates, resources, or deployment behavior.
- Runtime v0.41.0 service lifecycle compatibility guidance for ordered startup,
  reverse shutdown, partial-startup rollback, bounded cleanup, cancellation,
  and safe failure reporting without chart-owned services, hooks, values, or
  resources.
- Runtime v0.41.0 service registry compatibility guidance for explicit ordered
  registration, stable lookup, immutable discovery, duplicate protection, and
  sealed lifecycle ownership without chart-owned registry declarations,
  plugins, health aggregation, values, templates, or resources.
- Runtime v0.41.0 component health compatibility guidance and live endpoint
  validation for bounded statuses, concurrent deadlines, deterministic
  aggregation, transition events, and informational HTTP behavior without new
  chart values, probes, templates, resources, or recovery policy.
- Runtime v0.41.0 core capability registry compatibility guidance for canonical
  identities, explicit ordered registration, stable lookup, immutable
  discovery, duplicate protection, safe errors, sealing, and application-owned
  execution composition without chart-owned capability declarations,
  discovery endpoints, plugins, values, templates, probes, or resources.
- Runtime v0.41.0 bounded immutable capability metadata and ordered external
  discovery guidance, with live provider-free `GET /v1/capabilities` validation
  and no chart-owned configuration, declarations, templates, resources, probes,
  permissions, provider details, model details, or availability policy.
- Runtime v0.41.0 sealed-registry capability execution pipeline compatibility
  guidance and live in-pod invocation without chart-owned middleware, routing,
  values, templates, resources, probes, permissions, or execution policy.
- Runtime v0.41.0 ordered capability middleware compatibility guidance and live
  in-pod invocation without chart-owned middleware configuration, declarations,
  routing, values, templates, resources, probes, permissions, or execution
  policy.
- Runtime v0.41.0 optional capability lifecycle compatibility guidance and live
  in-pod startup and shutdown validation without chart-owned lifecycle values,
  declarations, templates, resources, probes, permissions, CRDs, or operator
  behavior.
- Runtime v0.41.0 capability availability compatibility guidance, positive
  schema-validated per-check deadline, ConfigMap rendering, public contract
  import, and live provider-free endpoint validation.
- Explicit separation of informational capability availability from execution,
  routing, retry, recovery, and Kubernetes startup, liveness, and readiness
  probes, without chart-owned declarations, resources, permissions, CRDs, or
  operator behavior.

The immediate focus is optional platform integration contracts and their
organization-owned composition. Chart opt-ins will be considered only after a
stable contract, explicit values, disabled defaults, render tests, and live
validation are available.

## Milestone 1 — Repository and chart foundation

**Status:** Completed

- [x] Dedicated `trussium-helm` repository and Apache-2.0 license.
- [x] Runtime-only chart name and ownership boundary established.
- [x] Production `trussium` application chart.
- [x] Complete value schema and operator documentation.
- [x] Automated quality, rendering, and Kind lifecycle validation.
- [x] Helm-native chart contract validation with no Python test harness.
- [x] Independent semantic release and OCI publication.

## Milestone 2 — Runtime compatibility operations

**Status:** Completed

- [x] Automate review-only proposals for newly released compatible runtime
  versions.
- [x] Publish an explicit chart-to-runtime compatibility policy and matrix.
- [x] Add release recovery and OCI publication recovery runbooks.
- [x] Validate supported Kubernetes minor versions in CI.

## Milestone 3 — Optional platform integrations

**Status:** In Progress

Integration policy: NetworkPolicy, ServiceMonitor, and Ingress remain
organization-owned by default. A future chart opt-in must satisfy ADR 0005's
contract, safety, and validation requirements.

- [x] Configurable HorizontalPodAutoscaler support after runtime metrics exist.
- [x] Configurable OpenTelemetry runtime tracing after instrumentation exists.
- [x] Portable runtime dashboard compatibility guidance without chart-owned
  dashboard or backend resources.
- [x] Portable runtime alerting compatibility guidance without chart-owned
  rules, notification routing, or backend resources.
- [x] Evaluate NetworkPolicy traffic and ownership contracts.
- [x] Add a disabled-by-default NetworkPolicy opt-in with explicit peers and
  egress destinations; keep CNI enforcement organization-owned.
- [x] Evaluate the ServiceMonitor scraping and ownership contract.
- [x] Add a disabled-by-default ServiceMonitor opt-in with explicit selectors
  and scrape settings; keep the Prometheus Operator organization-owned.
- [x] Evaluate Ingress routing and certificate ownership.
- [x] Add a disabled-by-default Ingress opt-in with explicit hosts, paths, and
  existing TLS Secret references; keep controller and certificate lifecycle
  organization-owned.

## Boundary

This chart will not install `trussium-operator`. An operator has a distinct
control-plane responsibility, lifecycle, RBAC surface, and release cadence and
will be packaged independently.
