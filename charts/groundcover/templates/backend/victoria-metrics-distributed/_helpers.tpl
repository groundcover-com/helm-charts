{{/*
Create the name for global ingest vmauth
backport https://github.com/VictoriaMetrics/helm-charts/pull/1520 into 0.4.2 (can drop once vm have released.)
*/}}
{{- define "victoria-metrics-distributed.vmauthIngestGlobalName" -}}
{{- printf "write-global-groundcover" -}}
{{- end }}

{{/*
Create the name for global query vmauth
backport https://github.com/VictoriaMetrics/helm-charts/pull/1520 into 0.4.2 (can drop once vm have released.)
*/}}
{{- define "victoria-metrics-distributed.vmauthQueryGlobalName" -}}
{{- printf "read-global-groundcover" }}
{{- end }}
