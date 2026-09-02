# Helm chart 1.2 release record

> **Published release.** This document records the preparation contract for
> chart `v1.2.0`; it is no longer a pending release plan.

Chart `v1.2.0` updates the default runtime compatibility target to `v1.22.0`.
The chart version remains independently managed from the runtime version.

The chart continues to install the Trussium runtime workload only. It does not
install the Kubernetes Operator. Existing Kubernetes `>=1.25` requirements,
values, health probes, metrics, and lifecycle contracts remain unchanged.

The published package was validated for rendering, package contents, Kind
lifecycle behavior, and the default runtime image tag. For installation and
post-release verification, follow [Release operations](RELEASES.md).
