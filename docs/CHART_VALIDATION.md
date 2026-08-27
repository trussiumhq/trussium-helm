# Chart validation

The chart is validated with Helm-native tooling so contributors do not need a
Python test harness or a YAML-specific runtime to verify chart behavior.

## Local checks

```bash
scripts/helm-validate.sh
scripts/chart-contract-test.sh
scripts/chart-package.sh
```

`helm-validate.sh` performs strict linting and schema-aware rendering.
`chart-contract-test.sh` renders representative configurations and checks the
deployment, service, autoscaling, probes, privacy boundaries, and expected
schema failures with `yq`, `jq`, and portable shell assertions.
`chart-package.sh` packages the chart and runs the package smoke test.

The Kind lifecycle test remains in `scripts/chart-smoke-test.sh`; it validates
live Kubernetes behavior and is intentionally separate from render-time
contract checks.

Python is not required for chart tests. It remains in the repository only for
the existing Python Semantic Release workflow.
