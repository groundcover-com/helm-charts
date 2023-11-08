{{- define "common.labels.standard" -}}
app.kubernetes.io/name: {{ include "common.names.name" . }}
{{ if eq .Chart.Name "clickhouse" }}
helm.sh/chart: clickhouse-3.2.1
{{ else }}
helm.sh/chart: {{ include "common.names.chart" . }}
{{- end }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
