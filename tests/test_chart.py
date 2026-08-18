from __future__ import annotations

import re
import subprocess
import tomllib
from pathlib import Path
from typing import Any, cast

import pytest
import yaml

REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
CHART = REPOSITORY_ROOT / "charts" / "trussium"
CUSTOM_VALUES = REPOSITORY_ROOT / "tests" / "fixtures" / "custom-values.yaml"


def run_helm(*arguments: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["helm", *arguments],
        cwd=REPOSITORY_ROOT,
        check=check,
        capture_output=True,
        text=True,
    )


def render(*arguments: str) -> list[dict[str, Any]]:
    result = run_helm(
        "template", "trussium", str(CHART), "--namespace", "trussium-system", *arguments
    )
    return [
        cast(dict[str, Any], document)
        for document in yaml.safe_load_all(result.stdout)
        if document is not None
    ]


def resource(documents: list[dict[str, Any]], kind: str) -> dict[str, Any]:
    return next(document for document in documents if document.get("kind") == kind)


def test_chart_metadata_tracks_runtime_independently() -> None:
    metadata = cast(dict[str, Any], yaml.safe_load((CHART / "Chart.yaml").read_text()))
    project = tomllib.loads((REPOSITORY_ROOT / "pyproject.toml").read_text())

    assert metadata["name"] == "trussium"
    assert metadata["type"] == "application"
    assert re.fullmatch(r"\d+\.\d+\.\d+", metadata["version"])
    assert metadata["version"] == project["project"]["version"]
    assert metadata["appVersion"] == "0.38.0"
    assert metadata["annotations"]["artifacthub.io/operator"] == "false"


def test_kind_validates_runtime_v038_capability_execution_pipeline() -> None:
    """Compatibility CI should bind the release and execution pipeline contract."""
    workflow = (REPOSITORY_ROOT / ".github" / "workflows" / "ci.yml").read_text()
    smoke_script = (REPOSITORY_ROOT / "scripts" / "chart-smoke-test.sh").read_text()
    root_readme = (REPOSITORY_ROOT / "README.md").read_text()
    chart_readme = (CHART / "README.md").read_text()

    assert "ref: v0.38.0" in workflow
    assert '"event":"runtime.configuration.loaded"' in smoke_script
    assert '"event":"provider.configuration.unavailable"' in smoke_script
    assert '"event":"observability.configuration.loaded"' in smoke_script
    assert '"event":"runtime.started"' in smoke_script
    assert '"event":"readiness.configuration.loaded"' in smoke_script
    assert "CHAT_CAPABILITY_NAME" in smoke_script
    assert "CHAT_CAPABILITY_METADATA" in smoke_script
    assert "CapabilityExecutionPipeline" in smoke_script
    assert "pipeline.execute(" in smoke_script
    assert "CapabilityRegistry" in smoke_script
    assert '"http://127.0.0.1:$port/v1/capabilities"' in smoke_script
    assert "capability discovery response" in smoke_script
    assert "blob/v0.38.0/docs/ERRORS.md" in root_readme
    assert "blob/v0.38.0/docs/ERRORS.md" in chart_readme
    assert "blob/v0.38.0/docs/LIFECYCLE.md" in root_readme
    assert "blob/v0.38.0/docs/LIFECYCLE.md" in chart_readme
    assert "blob/v0.38.0/docs/SERVICE_REGISTRY.md" in root_readme
    assert "blob/v0.38.0/docs/SERVICE_REGISTRY.md" in chart_readme
    assert "blob/v0.38.0/docs/COMPONENT_HEALTH.md" in root_readme
    assert "blob/v0.38.0/docs/COMPONENT_HEALTH.md" in chart_readme
    assert "blob/v0.38.0/docs/CAPABILITY_REGISTRY.md" in root_readme
    assert "blob/v0.38.0/docs/CAPABILITY_REGISTRY.md" in chart_readme
    assert "blob/v0.38.0/docs/CAPABILITY_DISCOVERY.md" in root_readme
    assert "blob/v0.38.0/docs/CAPABILITY_DISCOVERY.md" in chart_readme
    assert "blob/v0.38.0/docs/CAPABILITY_EXECUTION_PIPELINE.md" in root_readme
    assert "blob/v0.38.0/docs/CAPABILITY_EXECUTION_PIPELINE.md" in chart_readme
    assert "blob/v0.38.0/docs/HEALTH.md" in root_readme
    assert "blob/v0.38.0/docs/HEALTH.md" in chart_readme
    assert "blob/v0.38.0/docs/DASHBOARDS.md" in root_readme
    assert "blob/v0.38.0/docs/DASHBOARDS.md" in chart_readme
    assert "blob/v0.38.0/docs/ALERTING.md" in root_readme
    assert "blob/v0.38.0/docs/ALERTING.md" in chart_readme
    assert "blob/v0.38.0/deploy/observability/prometheus/rules/" in root_readme
    assert "blob/v0.38.0/deploy/observability/prometheus/rules/" in chart_readme
    assert "/health/components" in smoke_script
    assert '{"status":"ok","components":[]}' in smoke_script
    assert 'helm --kube-context "$context" get manifest' in smoke_script
    notes = (CHART / "templates" / "NOTES.txt").read_text()
    assert "Provider dependency readiness checks are enabled" in notes
    assert "model identifier is not printed here" in notes


def test_default_render_preserves_production_runtime_contract() -> None:
    documents = render()
    assert {document["kind"] for document in documents} == {
        "ConfigMap",
        "Deployment",
        "HorizontalPodAutoscaler",
        "PodDisruptionBudget",
        "Service",
        "ServiceAccount",
    }

    deployment = resource(documents, "Deployment")
    spec = deployment["spec"]
    pod_spec = spec["template"]["spec"]
    container = pod_spec["containers"][0]

    assert "replicas" not in spec
    assert spec["revisionHistoryLimit"] == 3
    assert spec["strategy"]["rollingUpdate"] == {"maxUnavailable": 0, "maxSurge": 1}
    assert pod_spec["automountServiceAccountToken"] is False
    assert pod_spec["enableServiceLinks"] is False
    assert pod_spec["terminationGracePeriodSeconds"] == 36
    assert pod_spec["securityContext"]["runAsUser"] == 10001
    assert pod_spec["securityContext"]["runAsGroup"] == 10001
    assert pod_spec["securityContext"]["seccompProfile"]["type"] == "RuntimeDefault"
    assert pod_spec["imagePullSecrets"] == [{"name": "ghcr-credentials"}]
    assert container["image"] == "ghcr.io/trussiumhq/trussium:0.38.0"
    assert container["ports"][0]["containerPort"] == 9000
    assert container["securityContext"]["readOnlyRootFilesystem"] is True
    assert container["securityContext"]["capabilities"]["drop"] == ["ALL"]
    assert container["startupProbe"]["httpGet"]["path"] == "/health/live"
    assert container["livenessProbe"]["httpGet"]["path"] == "/health/live"
    assert container["readinessProbe"]["httpGet"]["path"] == "/health/ready"
    assert container["envFrom"][1]["secretRef"] == {
        "name": "trussium-provider",
        "optional": True,
    }
    assert (
        pod_spec["topologySpreadConstraints"][0]["labelSelector"]["matchLabels"]
        == spec["selector"]["matchLabels"]
    )

    service = resource(documents, "Service")
    assert service["spec"]["type"] == "ClusterIP"
    assert service["spec"]["ports"][0] == {
        "name": "http",
        "port": 9000,
        "targetPort": "http",
        "protocol": "TCP",
    }

    budget = resource(documents, "PodDisruptionBudget")
    assert budget["spec"]["maxUnavailable"] == 1

    config_map = resource(documents, "ConfigMap")
    assert config_map["data"]["TRUSSIUM_READINESS__DEPENDENCY_CHECKS_ENABLED"] == "false"
    assert config_map["data"]["TRUSSIUM_READINESS__DEPENDENCY_TIMEOUT_SECONDS"] == "1"
    assert config_map["data"]["TRUSSIUM_READINESS__DEPENDENCY_CACHE_SECONDS"] == "10"
    assert "TRUSSIUM_READINESS__REQUIRED_MODEL" not in config_map["data"]
    assert config_map["data"]["TRUSSIUM_OBSERVABILITY__METRICS_ENABLED"] == "true"
    assert config_map["data"]["TRUSSIUM_OBSERVABILITY__TRACING_ENABLED"] == "false"
    assert config_map["data"]["TRUSSIUM_OBSERVABILITY__TRACING_SERVICE_NAME"] == "trussium"
    assert config_map["data"]["TRUSSIUM_OBSERVABILITY__TRACING_SAMPLE_RATIO"] == "1"
    assert (
        config_map["data"]["TRUSSIUM_OBSERVABILITY__OTLP_TRACES_ENDPOINT"]
        == "http://127.0.0.1:4318/v1/traces"
    )
    assert config_map["data"]["TRUSSIUM_OBSERVABILITY__OTLP_EXPORT_TIMEOUT_SECONDS"] == "10"

    autoscaler = resource(documents, "HorizontalPodAutoscaler")
    assert autoscaler["apiVersion"] == "autoscaling/v2"
    assert autoscaler["spec"]["scaleTargetRef"] == {
        "apiVersion": "apps/v1",
        "kind": "Deployment",
        "name": "trussium",
    }
    assert autoscaler["spec"]["minReplicas"] == 2
    assert autoscaler["spec"]["maxReplicas"] == 10
    assert autoscaler["spec"]["metrics"] == [
        {
            "type": "ContainerResource",
            "containerResource": {
                "name": "cpu",
                "container": "trussium",
                "target": {"type": "Utilization", "averageUtilization": 70},
            },
        }
    ]
    assert autoscaler["spec"]["behavior"] == {
        "scaleUp": {
            "stabilizationWindowSeconds": 0,
            "selectPolicy": "Max",
            "policies": [
                {"type": "Percent", "value": 100, "periodSeconds": 60},
                {"type": "Pods", "value": 4, "periodSeconds": 60},
            ],
        },
        "scaleDown": {
            "stabilizationWindowSeconds": 300,
            "selectPolicy": "Min",
            "policies": [
                {"type": "Percent", "value": 25, "periodSeconds": 60},
                {"type": "Pods", "value": 1, "periodSeconds": 60},
            ],
        },
    }


def test_custom_values_render_supported_integrations() -> None:
    documents = render("--values", str(CUSTOM_VALUES))
    assert not any(document["kind"] == "ServiceAccount" for document in documents)
    assert not any(document["kind"] == "HorizontalPodAutoscaler" for document in documents)

    deployment = resource(documents, "Deployment")
    assert deployment["metadata"]["name"] == "trussium-custom"
    assert deployment["spec"]["replicas"] == 3
    template = deployment["spec"]["template"]
    assert template["metadata"]["annotations"]["example.com/restarted-at"] == (
        "2026-08-11T00:00:00Z"
    )
    assert template["metadata"]["labels"]["example.com/tier"] == "serving"
    pod_spec = template["spec"]
    assert pod_spec["serviceAccountName"] == "trussium-existing"
    assert pod_spec["priorityClassName"] == "production-runtime"
    assert pod_spec["nodeSelector"] == {"kubernetes.io/os": "linux"}
    container = pod_spec["containers"][0]
    assert container["envFrom"][1]["secretRef"] == {
        "name": "organization-provider-secret",
        "optional": False,
    }
    assert container["env"] == [{"name": "EXAMPLE_DIRECT_VALUE", "value": "enabled"}]

    service = resource(documents, "Service")
    assert service["spec"]["type"] == "LoadBalancer"
    assert service["spec"]["ports"][0]["port"] == 8080
    assert service["metadata"]["annotations"]["example.com/service"] == "custom"

    config_map = resource(documents, "ConfigMap")
    assert config_map["data"]["TRUSSIUM_READINESS__DEPENDENCY_CHECKS_ENABLED"] == "true"
    assert config_map["data"]["TRUSSIUM_READINESS__DEPENDENCY_TIMEOUT_SECONDS"] == "0.75"
    assert config_map["data"]["TRUSSIUM_READINESS__DEPENDENCY_CACHE_SECONDS"] == "3.5"
    assert config_map["data"]["TRUSSIUM_READINESS__REQUIRED_MODEL"] == "required-model"
    assert config_map["data"]["TRUSSIUM_OBSERVABILITY__METRICS_ENABLED"] == "false"
    assert config_map["data"]["TRUSSIUM_OBSERVABILITY__TRACING_ENABLED"] == "true"
    assert config_map["data"]["TRUSSIUM_OBSERVABILITY__TRACING_SERVICE_NAME"] == "trussium-custom"
    assert config_map["data"]["TRUSSIUM_OBSERVABILITY__TRACING_SAMPLE_RATIO"] == "0.25"
    assert (
        config_map["data"]["TRUSSIUM_OBSERVABILITY__OTLP_TRACES_ENDPOINT"]
        == "https://collector.example/v1/traces"
    )
    assert config_map["data"]["TRUSSIUM_OBSERVABILITY__OTLP_EXPORT_TIMEOUT_SECONDS"] == "2.5"


def test_chart_does_not_render_credentials() -> None:
    result = run_helm("template", "trussium", str(CHART))

    assert "kind: Secret" not in result.stdout
    assert "API_KEY" not in result.stdout
    assert "YOUR_GITHUB_TOKEN" not in result.stdout


def test_chart_does_not_render_observability_backends_dashboards_or_alerts() -> None:
    """Portable observability artifacts and backend lifecycle stay operator-owned."""
    rendered = run_helm("template", "trussium", str(CHART)).stdout.lower()

    assert "grafana" not in rendered
    assert "loki" not in rendered
    assert "tempo" not in rendered
    assert "alertmanager" not in rendered
    assert "servicemonitor" not in rendered
    assert "podmonitor" not in rendered
    assert "prometheusrule" not in rendered
    assert "alertmanagerconfig" not in rendered
    assert "dashboard" not in rendered
    assert "alerting" not in rendered

    validate_script = (REPOSITORY_ROOT / "scripts" / "helm-validate.sh").read_text()
    package_script = (REPOSITORY_ROOT / "scripts" / "package-smoke-test.sh").read_text()
    assert "observability backends, dashboards, and alerts must remain operator-owned" in (
        validate_script
    )
    assert "packaged chart must not bundle observability backends, dashboards, or alerts" in (
        package_script
    )


def test_schema_rejects_invalid_values() -> None:
    result = run_helm(
        "template",
        "trussium",
        str(CHART),
        "--set",
        "replicaCount=0",
        check=False,
    )

    assert result.returncode != 0
    assert "replicaCount" in result.stderr
    assert "Must be greater than or equal to 1" in result.stderr


def test_recreate_strategy_omits_rolling_update_settings() -> None:
    deployment = resource(render("--set", "deploymentStrategy.type=Recreate"), "Deployment")

    assert deployment["spec"]["strategy"] == {"type": "Recreate"}


def test_schema_rejects_invalid_autoscaling_target() -> None:
    result = run_helm(
        "template",
        "trussium",
        str(CHART),
        "--set",
        "autoscaling.targetCPUUtilizationPercentage=0",
        check=False,
    )

    assert result.returncode != 0
    assert "targetCPUUtilizationPercentage" in result.stderr
    assert "Must be greater than or equal to 1" in result.stderr


def test_schema_rejects_unknown_observability_values() -> None:
    result = run_helm(
        "template",
        "trussium",
        str(CHART),
        "--set",
        "observability.tracing.unexpected=true",
        check=False,
    )

    assert result.returncode != 0
    assert "unexpected" in result.stderr
    assert "Additional property" in result.stderr


def test_schema_rejects_unknown_readiness_values() -> None:
    result = run_helm(
        "template",
        "trussium",
        str(CHART),
        "--set",
        "readiness.unexpected=true",
        check=False,
    )

    assert result.returncode != 0
    assert "unexpected" in result.stderr
    assert "Additional property" in result.stderr


@pytest.mark.parametrize(
    ("flag", "setting", "value"),
    [
        ("--set", "dependencyTimeoutSeconds", "0"),
        ("--set", "dependencyCacheSeconds", "0"),
        ("--set-string", "requiredModel", "   "),
    ],
)
def test_schema_rejects_invalid_readiness_values(
    flag: str,
    setting: str,
    value: str,
) -> None:
    result = run_helm(
        "template",
        "trussium",
        str(CHART),
        flag,
        f"readiness.{setting}={value}",
        check=False,
    )

    assert result.returncode != 0
    assert setting in result.stderr


@pytest.mark.parametrize(
    ("flag", "setting", "value"),
    [
        ("--set-string", "serviceName", ""),
        ("--set", "sampleRatio", "-0.1"),
        ("--set", "sampleRatio", "1.1"),
        ("--set-string", "otlpTracesEndpoint", "grpc://collector:4317"),
        ("--set", "otlpExportTimeoutSeconds", "0"),
    ],
)
def test_schema_rejects_invalid_tracing_values(
    flag: str,
    setting: str,
    value: str,
) -> None:
    result = run_helm(
        "template",
        "trussium",
        str(CHART),
        flag,
        f"observability.tracing.{setting}={value}",
        check=False,
    )

    assert result.returncode != 0
    assert setting in result.stderr


def test_template_rejects_inverted_autoscaling_bounds() -> None:
    result = run_helm(
        "template",
        "trussium",
        str(CHART),
        "--set",
        "autoscaling.minReplicas=11",
        check=False,
    )

    assert result.returncode != 0
    assert "autoscaling.minReplicas must be less than or equal" in result.stderr
