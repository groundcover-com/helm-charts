{{- define "metrics-ingester.fullname" -}}
{{- printf "%s-metrics-ingester" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "metrics-ingester.http.scheme" -}}
{{- ternary "https" "http" .Values.global.metrics.tls.enabled -}}
{{- end -}}

{{- define "metrics-ingester.base.http.url" -}}
{{- if .Values.global.metrics.overrideUrl -}}
    {{- .Values.global.metrics.overrideUrl -}}
{{- else if .Values.global.ingress.site -}}
    {{- include "incloud.metrics.http.url" . -}}
{{- else if not .Values.global.backend.enabled -}}
    {{- fail "A valid global.domain or .Values.global.metrics.overrideUrl is required!" -}}
{{- else -}}
    {{- printf "%s://%s:%d" (include "metrics-ingester.http.scheme" .) (include "metrics-ingester.fullname" .) (index .Values.global "metrics-ingester" "service" "servicePort" | int ) -}}
{{- end -}}
{{- end -}}

{{- define "metrics-ingester.write.http.url" -}}
{{- printf "%s/api/v1/write" (include "metrics-ingester.base.http.url" .) -}}
{{- end -}}

{{- define "metrics-ingester.health.http.url" -}}
{{- printf "%s/health" (include "metrics-ingester.base.http.url" .) -}}
{{- end -}}
