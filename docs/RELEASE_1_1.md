# Helm chart 1.1 release preparation

The next chart release is a compatibility update for runtime `v1.17.0`.
`appVersion` will target `1.17.0`; the chart version remains independently
managed and is expected to advance to `v1.1.0` through the normal semantic
release workflow.

The chart continues to install the Trussium runtime workload only. It does not
install the Kubernetes Operator. Existing Kubernetes `>=1.25` requirements,
values, health probes, metrics, and lifecycle contracts remain unchanged.

Before publication, CI must validate rendering, package contents, Kind
lifecycle behavior, and the default runtime image tag.
