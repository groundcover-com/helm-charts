# Release notes for version 0.27.6

**Release date:** 2024-10-21

![AppVersion: v1.105.0](https://img.shields.io/static/v1?label=AppVersion&message=v1.105.0&color=success&logo=)
![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

- Add an explicit fail in case both Grafana dashboard via sidecar and `grafana.dashboards` are enabled. Previously, this configuration would be accepted and sidecar configuration would silently override `.grafana.dashboards` configuration. See [these docs](https://docs.victoriametrics.com/helm/victoriametrics-k8s-stack/#adding-external-dashboards) for information about adding external dashboards.
- bump version of VM components to [v1.105.0](https://github.com/VictoriaMetrics/VictoriaMetrics/releases/tag/v1.105.0)

