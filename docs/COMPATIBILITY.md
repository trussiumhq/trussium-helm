# Chart and runtime compatibility

The Helm chart and Trussium runtime are released independently. A chart release
records its default runtime target in `charts/trussium/Chart.yaml` under
`appVersion`; the chart version controls the templates, schema, and packaging.

## Supported matrix

| Chart release | Default runtime image | Kubernetes |
| --- | --- | --- |
| `1.0.x` | `1.0.x` | `>=1.25` |
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
