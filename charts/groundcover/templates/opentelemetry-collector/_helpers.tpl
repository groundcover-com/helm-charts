{{- define "opentelemetry-collector.fullname" -}}
{{- printf "%s-opentelemetry-collector" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "logs.retentionDays" -}}
{{- .Values.global.logs.retentionDays | int }}
{{- end }}

{{- define "loki.url" -}}
{{- $lokiBaseUrl := "" -}}
{{- if not .Values.backend.enabled -}}
    {{- $lokiBaseUrl = (required "A valid global.logs.overrideUrl is required!" .Values.global.logs.overrideUrl) -}}
{{- else -}}
    {{- $lokiBaseUrl = (printf "http://%s:%d" (include "opentelemetry-collector.fullname" .) (index .Values.global "opentelemetry-collector" "ports" "loki-http" "servicePort" | int )) -}}
{{- end -}}
{{- printf "%s/loki/api/v1/push" $lokiBaseUrl -}}
{{- end -}}
