# Security Policy

Do not report vulnerabilities through a public issue.

Use GitHub's private vulnerability reporting for
`trussiumhq/trussium-helm`, or contact the repository maintainers privately if
that feature is unavailable. Include affected chart and runtime versions,
reproduction steps, impact, and any proposed mitigation.

Supported chart releases are the latest minor release and its current patch
line. Runtime vulnerabilities are handled in the
[Trussium runtime repository](https://github.com/trussiumhq/trussium/security).

The chart deliberately references externally managed provider and image-pull
Secrets. Never place credential values in `values.yaml`, issue reports, logs,
or pull requests.
