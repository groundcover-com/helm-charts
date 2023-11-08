{{- define "opentelemetry-collector.fullname" -}}
{{- printf "%s-opentelemetry-collector" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "logs.retentionDays" -}}
{{- .Values.global.logs.retentionDays | int }}
{{- end }}

{{- define "loki.url" -}}
{{- if .Values.global.logs.overrideUrl  -}}
    {{- printf "%s/loki/api/v1/push" .Values.global.logs.overrideUrl -}}
{{- else -}}
    {{- printf "http://%s:%d/loki/api/v1/push" (include "opentelemetry-collector.fullname" .) (index .Values.global "opentelemetry-collector" "ports" "loki-http" "servicePort" | int ) -}}
{{- end -}}
{{- end -}}
