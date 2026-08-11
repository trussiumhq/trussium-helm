# Release operations

Chart releases use Conventional Commits and Python Semantic Release. The chart
version is independent from the Trussium runtime version. `Chart.yaml`'s
`appVersion` records the default runtime compatibility target.

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
