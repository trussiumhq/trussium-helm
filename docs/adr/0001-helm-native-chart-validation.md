# ADR 0001: Use Helm-native chart validation

- Status: Accepted
- Date: 2026-08-27

## Context

The chart previously used a Python/Pytest harness to inspect rendered YAML.
That duplicated Helm's lint, schema, and rendering behavior and required a
Python dependency stack for a Helm-only repository.

## Decision

Use Helm, `yq`, `jq`, and portable POSIX-style shell scripts for render-time
chart contract tests. Keep the separate Kind smoke test for live Kubernetes
validation. Retain Python only for Python Semantic Release, which is part of
the release workflow rather than chart validation.

## Consequences

- Chart checks are closer to the behavior users deploy and are easier to run
  in minimal CI environments.
- The repository no longer needs Pytest, Ruff, MyPy, or PyYAML for chart tests.
- `yq` and `jq` become required tools for the contract script.
- Live Kubernetes behavior continues to require Helm, kubectl, and Kind.
