# Release operations

Chart releases use Conventional Commits and Python Semantic Release. The chart
version is independent from the Trussium runtime version. `Chart.yaml`'s
`appVersion` records the default runtime compatibility target.

When the default runtime changes, update the [compatibility policy and
matrix](COMPATIBILITY.md), the chart contract test, and the roadmap in the same
pull request. The change must be validated against the runtime lifecycle before
release.

The weekly Runtime Compatibility Proposal workflow checks the latest runtime
release and opens a review-only pull request when the target changes. A
maintainer must review the generated compatibility diff and lifecycle checks;
the workflow never merges, publishes, or deploys automatically. Use its manual
`runtime_version` input to rehearse a proposal for a specific release.

On a merge to `main`, the release workflow:

1. Calculates the next semantic chart version.
2. Updates `pyproject.toml` and `charts/trussium/Chart.yaml`.
3. Runs strict linting and packages `dist/trussium-<version>.tgz`.
4. Creates the release commit, tag, and GitHub release.
5. Attaches the packaged chart to the GitHub release.
6. Publishes the same package to `oci://ghcr.io/trussiumhq/charts`.

Before merging a release-bearing change, confirm CI and the local package smoke
test pass. After release, verify the Git tag, GitHub asset, OCI pull, chart
metadata, and default rendering:

```bash
helm pull oci://ghcr.io/trussiumhq/charts/trussium --version VERSION
helm show chart trussium-VERSION.tgz
helm template trussium trussium-VERSION.tgz --namespace trussium-system
```

If semantic versioning succeeds but publication fails, rerun the release job
for the release commit. Do not create a second version commit. If the OCI push
alone fails, download the GitHub release asset, authenticate with a package
write token, validate the package, and push that exact artifact.
