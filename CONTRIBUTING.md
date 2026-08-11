# Contributing

Thank you for improving the Trussium Helm chart.

## Workflow

1. Open or confirm a GitHub issue describing the change and acceptance criteria.
2. Create a focused branch from an updated `main`.
3. Keep runtime defaults aligned with a released Trussium Kubernetes contract.
4. Add rendering and lifecycle coverage for behavior changes.
5. Run the complete validation suite before opening a pull request.

```bash
uv sync
uv run ruff check .
uv run ruff format --check .
uv run mypy tests
uv run pytest
scripts/helm-validate.sh
scripts/chart-package.sh
TRUSSIUM_RUNTIME_SOURCE=../trussium scripts/chart-smoke-test.sh
```

Use [Conventional Commits](https://www.conventionalcommits.org/) because commit
types drive independent chart releases. A `feat:` change creates a minor
pre-1.0 release, `fix:` creates a patch release, and a breaking change creates
a major release.

Pull requests must begin with `Closes #<issue-number>` and describe the
summary, motivation, implementation, testing, manual validation, risks,
compatibility, documentation, and checklist.

Do not add provider credentials, registry tokens, rendered Secrets, or example
values that resemble real credentials.
