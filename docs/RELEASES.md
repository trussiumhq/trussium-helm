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

## Recovery runbooks

### Versioning or release-commit failure

1. Open the failed workflow run and record the source commit and the last
   published tag.
2. Check whether the release commit and tag already exist:

   ```bash
   git fetch --tags origin
   git show vVERSION
   gh release view vVERSION
   ```

3. If no tag was created, rerun the failed release job for the original `main`
   commit. Do not amend `pyproject.toml`, `Chart.yaml`, or create a manual tag.
4. If the tag exists, do not rerun versioning. Continue with the publication
   recovery steps below.

### GitHub release asset failure

If the release commit and tag exist but the GitHub release or chart asset is
missing, rerun only the publish step for that tag:

```bash
uv run semantic-release publish --tag vVERSION
gh release view vVERSION
gh release download vVERSION --pattern 'trussium-*.tgz' --dir /tmp/trussium-release
scripts/package-smoke-test.sh /tmp/trussium-release
```

Use the release commit’s generated package. Never rebuild a package from a
different commit and attach it to an existing release.

### OCI publication failure

1. Confirm the GitHub release asset and validate it locally:

   ```bash
   gh release download vVERSION --pattern 'trussium-*.tgz' --dir /tmp/trussium-release
   scripts/package-smoke-test.sh /tmp/trussium-release
   ```

2. Authenticate with a token that has package write access:

   ```bash
   printf '%s' "$GHCR_TOKEN" | helm registry login ghcr.io \
     --username GITHUB_USERNAME --password-stdin
   ```

3. Push the exact downloaded artifact:

   ```bash
   helm push /tmp/trussium-release/trussium-VERSION.tgz \
     oci://ghcr.io/trussiumhq/charts
   helm pull oci://ghcr.io/trussiumhq/charts/trussium --version VERSION
   ```

Do not bump the chart version or rerun semantic-release for an OCI-only
failure. Escalate if the package digest differs from the GitHub release asset
or if the registry reports an existing conflicting version.
