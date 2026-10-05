# Chart and runtime compatibility

The Helm chart and Trussium runtime are released independently. A chart release
records its default runtime target in `charts/trussium/Chart.yaml` under
`appVersion`; the chart version controls the templates, schema, and packaging.

## Supported matrix

| Chart release | Default runtime image | Kubernetes |
| --- | --- | --- |
| `1.3.x` | `1.27.x` | `>=1.25` |
| `1.2.x` | `1.22.x` | `>=1.25` |
| `1.0.x` | `1.17.x` | `>=1.25` |
| `0.5.x` | `0.41.x` | `>=1.25` |
| `0.4.9` | `0.40.x` | `>=1.25` |
| `0.4.8` | `0.39.x` | `>=1.25` |
| `0.4.7` | `0.38.x` | `>=1.25` |
| `0.4.6` | `0.37.x` | `>=1.25` |
| `0.4.5` | `0.36.x` | `>=1.25` |
| `0.4.4` | `0.35.x` | `>=1.25` |
| `0.4.3` | `0.34.x` | `>=1.25` |
| `0.4.2` | `0.33.x` | `>=1.25` |
| `0.4.1` | `0.32.x` | `>=1.25` |
| `0.4.0` | `0.31.x` | `>=1.25` |

The current release is the first row. Historical rows preserve the documented
compatibility targets for existing installations.

## Policy

Compatibility is established by rendering and live lifecycle validation of the
default runtime image with the chart. A runtime compatibility update must also
update `Chart.yaml`, the contract test image assertion, this matrix, and the
release notes or roadmap entry in the same change.

The chart requires Kubernetes `>=1.25`. CI renders and strictly lints against
Kubernetes `1.25`, `1.29`, and `1.31`, and confirms that `1.24` is rejected by
the chart contract. Kubernetes support is a chart contract,
not a runtime version guarantee; cluster admission, storage, networking, and
provider connectivity remain operator responsibilities.

Overriding `image.tag` is supported for operators who have validated that
runtime against the chart. The chart cannot guarantee compatibility for an
arbitrary image override and does not automatically select or install runtime
versions.

## Automated compatibility proposals

The weekly `Runtime Compatibility Proposal` workflow opens a review-only pull
request when it finds a runtime target that differs from the chart metadata.
It runs on a schedule or a maintainer's manual dispatch and does not merge,
publish, or deploy changes. The generated pull request must pass the chart
validation checks and be reviewed before merge.

The workflow needs repository Actions settings to permit workflow tokens to
create pull requests. If a run fails with `GitHub Actions is not permitted to
create or approve pull requests`, an administrator can either enable the
repository setting **Allow GitHub Actions to create and approve pull
requests**, or configure a dedicated fine-grained `PAT` repository secret with
only `Contents: read/write` and `Pull requests: read/write` access. The
workflow already limits its token permissions to `contents: write` and
`pull-requests: write`; do not grant broader organization-wide permissions.
After changing the setting or secret, rerun the failed workflow and verify
that the proposal PR is opened without being merged automatically.
