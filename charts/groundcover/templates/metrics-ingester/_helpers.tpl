{{- define "metrics-ingester.fullname" -}}
{{- printf "%s-metrics-ingester" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "metrics-ingester.http.scheme" -}}
{{- ternary "https" "http" .Values.global.metrics.tls.enabled -}}
{{- end -}}

{{- define "metrics-ingester.cluster.http.write.url" -}}
{{- printf "%s/api/v1/write" (include "metrics-ingester.cluster.http.base.url" .) -}}
{{- end -}}

{{- define "metrics-ingester.cluster.http.base.url" -}}
{{- printf "%s://%s:%d" (include "metrics-ingester.http.scheme" .) (include "metrics-ingester.fullname" .) (index .Values.global "metrics-ingester" "service" "servicePort" | int ) -}}
{{- end -}}

{{- define "metrics-ingester.base.http.url" -}}
{{- if .Values.global.metrics.overrideUrl -}}
    {{- .Values.global.metrics.overrideUrl -}}
{{- else if and .Values.global.airgap .Values.global.backend.enabled -}}
    {{- include "metrics-ingester.cluster.http.base.url" . -}}
{{- else if .Values.global.ingress.site -}}
    {{- include "incloud.metrics.http.url" . -}}
{{- else if not .Values.global.backend.enabled -}}
    {{- fail "A valid global.ingress.site or .Values.global.metrics.overrideUrl is required!" -}}
{{- else -}}
    {{- include "metrics-ingester.cluster.http.base.url" . -}}
{{- end -}}
{{- end -}}

{{- define "metrics-ingester.datadog.http.v1.url" -}}
{{- printf "%s/datadog/api/v1/series" (include "metrics-ingester.base.http.url" .) -}}
{{- end -}}

{{- define "metrics-ingester.datadog.http.v2.url" -}}
{{- printf "%s/datadog/api/v2/series" (include "metrics-ingester.base.http.url" .) -}}
{{- end -}}

{{- define "metrics-ingester.write.http.url" -}}
{{- printf "%s/api/v1/write" (include "metrics-ingester.base.http.url" .) -}}
{{- end -}}

{{- define "metrics-ingester.health.http.url" -}}
{{- printf "%s/health" (include "metrics-ingester.base.http.url" .) -}}
{{- end -}}

{{- define "metrics-ingester.promethues-exposition.http.url" -}}
{{- printf "%s/api/v1/import/prometheus" (include "metrics-ingester.base.http.url" .) -}}
{{- end -}}
