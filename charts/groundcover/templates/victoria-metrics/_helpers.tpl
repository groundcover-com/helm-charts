{{- define "victoria-metrics.base.http.url" -}}
{{- if .Values.global.backend.enabled -}}
    {{- printf "http://%s:%d" (include "victoria-metrics.server.fullname" .) (index .Values.global "victoria-metrics" "service" "servicePort" | int ) -}}
{{- else if .Values.global.metrics.overrideUrl -}}
    {{- .Values.global.metrics.overrideUrl -}}
{{- else if .Values.global.ingress.site -}}
    {{- include "incloud.metrics.http.url" . -}}
{{- else -}}
    {{- fail "A valid global.domain or .Values.global.metrics.overrideUrl is required!" -}}
{{- end -}}
{{- end -}}

{{- define "victoria-metrics.write.http.url" -}}
{{- printf "%s/api/v1/write" (include "victoria-metrics.base.http.url" .) -}}
{{- end -}}
