# Roadmap

_Last updated: August 2026_

This repository owns the independently versioned Helm distribution for the
Trussium runtime. Runtime code and static Kustomize manifests remain in
[`trussium`](https://github.com/trussiumhq/trussium); the future operator
remains a separate project.

## Current focus

The first production Helm chart now carries the validated Trussium v0.24.0
Kubernetes contract into an independently released distribution:

- Hardened replicated runtime pods.
- Configurable non-secret runtime settings and existing Secret integration.
- Private-registry authentication, health probes, resource boundaries,
  topology spreading, zero-unavailable rolling updates, disruption protection,
  and bounded graceful shutdown.
- Schema-validated values and deterministic render tests.
- A real Kind lifecycle test covering install, health, upgrade, rollback, and
  uninstall.
- Independent Conventional Commit releases with GitHub and OCI artifacts.

The immediate focus is runtime compatibility operations: automated runtime
version proposals, an explicit compatibility matrix, release recovery
runbooks, and validation across supported Kubernetes minor versions.

## Milestone 1 — Repository and chart foundation

**Status:** Completed

- [x] Dedicated `trussium-helm` repository and Apache-2.0 license.
- [x] Runtime-only chart name and ownership boundary established.
- [x] Production `trussium` application chart.
- [x] Complete value schema and operator documentation.
- [x] Automated quality, rendering, and Kind lifecycle validation.
- [x] Independent semantic release and OCI publication.

## Milestone 2 — Runtime compatibility operations

**Status:** Planned

- Automate proposals for newly released compatible runtime versions.
- Publish an explicit chart-to-runtime compatibility policy and matrix.
- Add release recovery and OCI publication recovery runbooks.
- Validate supported Kubernetes minor versions in CI.

## Milestone 3 — Optional platform integrations

**Status:** Planned

- Configurable HorizontalPodAutoscaler support after runtime metrics exist.
- Optional NetworkPolicy after supported network contracts are defined.
- Optional ServiceMonitor after observability endpoints stabilize.
- Optional Ingress integration without owning certificate issuance.

## Boundary

This chart will not install `trussium-operator`. An operator has a distinct
control-plane responsibility, lifecycle, RBAC surface, and release cadence and
will be packaged independently.
