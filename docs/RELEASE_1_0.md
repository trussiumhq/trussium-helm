# Helm chart 1.0 release

The `trussium` chart 1.0.0 is the stable chart contract for deploying the
Trussium runtime 1.0.0 on Kubernetes 1.25 or newer. The chart remains focused
on runtime deployment; it does not install `trussium-operator`.

The chart version controls templates, values, schema, and packaging. The
`appVersion` identifies the default runtime image. Operators may override the
image tag only after validating that runtime against this chart.

SDKs, provider adapters, and other repositories are independent and optional;
they are not required to install or operate this chart.
