{{- define "victoria-metrics.base.http.url" -}}
{{- if .Values.global.backend.enabled -}}
    {{- include "victoria-metrics.cluster.http.base.url" . -}}
{{- else if .Values.global.metrics.overrideUrl -}}
    {{- .Values.global.metrics.overrideUrl -}}
{{- else if .Values.global.ingress.site -}}
    {{- include "incloud.ingestion.http.url" . -}}
{{- else -}}
    {{- fail "A valid global.ingress.site or .Values.global.metrics.overrideUrl is required!" -}}
{{- end -}}
{{- end -}}

{{- define "victoria-metrics.cluster.http.base.url" -}}
{{- printf "http://%s:%d" (include "victoria-metrics.server.fullname" .) (index .Values.global "victoria-metrics" "service" "servicePort" | int ) -}}
{{- end -}}

{{- define "victoria-metrics.write.http.url" -}}
{{- printf "%s/api/v1/write" (include "victoria-metrics.base.http.url" .) -}}
{{- end -}}

{{- define "victoria-metrics.service.fullname" -}}
{{- printf "%s-victoria-metrics" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
