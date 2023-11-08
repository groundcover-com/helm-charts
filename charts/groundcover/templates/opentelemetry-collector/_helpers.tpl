{{- define "opentelemetry-collector.fullname" -}}
{{- printf "%s-opentelemetry-collector" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{- define "logs.retention" -}}
{{- if .Values.global.logs.retentionDays -}}
{{- printf "%dd" (.Values.global.logs.retentionDays | int)}}
{{- else -}}
{{ .Values.global.logs.retention }}
{{- end -}}
{{- end -}}

{{- define "traces.retention" -}}
{{ .Values.global.traces.retention }}
{{- end -}}

{{- define "opentelemetry-collector.otlp.scheme" -}}
{{- ternary "https" "http" .Values.global.otlp.tls.enabled -}}
{{- end -}}

{{- define "opentelemetry-collector.tlsConfig" -}}
{{- ternary (dict "key_file" "/etc/ssl/certs/tls.key" "cert_file" "/etc/ssl/certs/tls.crt" | toJson) "null" .Values.global.otlp.tls.enabled -}}
{{- end -}}

{{- define "opentelemetry-collector.loki.http.url" -}}
{{- $lokiBaseUrl := "" -}}
{{- if not .Values.backend.enabled -}}
    {{- $lokiBaseUrl = (required "A valid global.logs.overrideUrl is required!" .Values.global.logs.overrideUrl) -}}
{{- else -}}
    {{- $lokiBaseUrl = (printf "%s://%s:%d" (include "opentelemetry-collector.otlp.scheme" .) (include "opentelemetry-collector.fullname" .) (index .Values.global "opentelemetry-collector" "ports" "loki-http" "servicePort" | int )) -}}
{{- end -}}
{{- printf "%s/loki/api/v1/push" $lokiBaseUrl -}}
{{- end -}}

{{- define "opentelemetry-collector.otlp.http.url" -}}
{{- if not .Values.backend.enabled -}}
    {{- required "A valid global.otlp.overrideHttpURL is required!" .Values.global.otlp.overrideHttpURL -}}
{{- else -}}
    {{- printf "%s://%s:%d" (include "opentelemetry-collector.otlp.scheme" .) (include "opentelemetry-collector.fullname" .) (index .Values.global "opentelemetry-collector" "ports" "otlp-http" "servicePort" | int ) -}}
{{- end -}}
{{- end -}}

{{- define "opentelemetry-collector.otlp.grpc.url" -}}
{{- if not .Values.backend.enabled -}}
    {{- required "A valid global.otlp.overrideGrpcURL is required!" .Values.global.otlp.overrideGrpcURL -}}
{{- else -}}
    {{- printf "%s:%d" (include "opentelemetry-collector.fullname" .) (index .Values.global "opentelemetry-collector" "ports" "otlp" "servicePort" | int ) -}}
{{- end -}}
{{- end -}}

{{- define "opentelemetry-collector.health.http.url" -}}
{{- $baseUrl := "" -}}
{{- if not .Values.backend.enabled -}}
    {{- $baseUrl = (required "A valid global.otlp.overrideHttpURL is required!" .Values.global.otlp.overrideHttpURL) -}}
{{- else -}}
    {{- $baseUrl = (printf "%s://%s:%d" (include "opentelemetry-collector.otlp.scheme" .) (include "opentelemetry-collector.fullname" .) (index .Values.global "opentelemetry-collector" "ports" "health" "servicePort" | int )) -}}
{{- end -}}
{{- printf "%s/health" $baseUrl -}}
{{- end -}}
