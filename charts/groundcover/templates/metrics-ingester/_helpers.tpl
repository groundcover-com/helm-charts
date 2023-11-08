{{- define "metrics-ingester.fullname" -}}
{{- printf "%s-metrics-ingester" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "metrics-ingester.http.scheme" -}}
{{- ternary "https" "http" .Values.global.metrics.tls.enabled -}}
{{- end -}}

{{- define "metrics-ingester.base.http.url" -}}
{{- if not .Values.backend.enabled -}}
    {{- required "A valid global.metrics.overrideUrl is required!" .Values.global.metrics.overrideUrl -}}
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
