{{- define "ingestor.fullname" -}}
    {{- printf "%s-ingestor" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ingestor.monitoring.port" -}}
    {{- default 9102 (.Values.ingestor.monitoring).port -}}
{{- end -}}

{{- define "ingestor.otlphttp.port" -}}
   4318
{{- end -}}

{{- define "ingestor.otlp.http.url" -}}
{{- if .Values.global.otlp.overrideHttpURL -}}
    {{- print .Values.global.otlp.overrideHttpURL -}}
{{- else if .Values.global.ingress.site -}}
    {{- include "incloud.otel.http.url" . -}}
{{- else if not .Values.global.backend.enabled -}}
    {{- fail "A valid global.ingress.site or global.otlp.overrideHttpURL is required!" -}}
{{- else -}}
    {{- printf "http://%s:%s"  (include "ingestor.fullname" .) (include "ingestor.otlphttp.port" .) -}}
{{- end -}}
{{- end -}}

{{- define "ingestor.otlptraces.cluster.http.url" -}}
    {{- printf "http://%s:%s/v1/traces" (include "ingestor.fullname" .) (include "ingestor.otlphttp.port" .) -}}
{{- end -}}

{{- define "ingestor.otlptraces.http.url" -}}
    {{- printf "%s/v1/traces" (include "ingestor.otlp.http.url" .) -}}
{{- end -}}

{{- define "ingestor.otlplogs.http.url" -}}
    {{- printf "%s/v1/logs" (include "ingestor.otlp.http.url" .) -}}
{{- end -}}

{{- define "ingestor.rumsourcemaps.http.url" -}}
    {{- $port := .Values.ingestor.rum.sourceMaps.port | required "ingestor.rum.sourceMaps.port is required" -}}
    {{- printf "http://%s:%d" (include "ingestor.fullname" .) ($port | int) -}}
{{- end -}}