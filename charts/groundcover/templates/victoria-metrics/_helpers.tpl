{{- define "victoria-metrics.base.http.url" -}}
{{- if .Values.global.metrics.overrideUrl -}}
    {{- .Values.global.metrics.overrideUrl -}}
{{- else -}}
    {{- printf "http://%s:%d" (include "victoria-metrics.server.fullname" .) (index .Values.global "victoria-metrics" "service" "servicePort" | int ) -}}
{{- end -}}
{{- end -}}

{{- define "victoria-metrics.write.http.url" -}}
{{- printf "%s/api/v1/write" (include "victoria-metrics.base.http.url" .) -}}
{{- end -}}
