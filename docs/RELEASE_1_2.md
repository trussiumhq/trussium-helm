# Helm chart 1.2 release preparation

The next chart release updates the default runtime compatibility target to
`v1.22.0`. The chart version remains independently managed and is expected to
advance to `v1.2.0` through the normal semantic release workflow.

The chart continues to install the Trussium runtime workload only. It does not
install the Kubernetes Operator. Existing Kubernetes `>=1.25` requirements,
values, health probes, metrics, and lifecycle contracts remain unchanged.

Before publication, CI must validate rendering, package contents, Kind
lifecycle behavior, and the default runtime image tag.
