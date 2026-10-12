{{- define "autonomous-infrastructure.fullname" -}}
{{- printf "%s-autoinfra" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "autonomous-infrastructure.configMapName" -}}
{{- printf "%s-config" (include "autonomous-infrastructure.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "autonomous-infrastructure.labels" -}}
{{- include "groundcover.labels" . }}
app: autoinfra
app.kubernetes.io/name: autoinfra
{{- end -}}

{{/* In-cluster ingestor OTLP/HTTP base URL, shared by both workers (as comm-hub and dispatch-center target it for traces). */}}
{{- define "autonomous-infrastructure.otlpEndpoint" -}}
{{- printf "http://%s:%s" (include "ingestor.fullname" .) (include "ingestor.otlphttp.port" .) -}}
{{- end -}}
