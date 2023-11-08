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
{{- $baseUrl := "" -}}
{{- if .Values.global.logs.overrideUrl -}}
    {{- $baseUrl = .Values.global.logs.overrideUrl -}}
{{- else if .Values.global.ingress.site -}}
    {{- $baseUrl = (printf "https://api-otel-http.%s" .Values.global.ingress.site) -}}
{{- else if not .Values.global.backend.enabled -}}
    {{- fail "A valid global.ingress.site or global.logs.overrideUrl is required!" -}}
{{- else -}}
    {{- $baseUrl = (printf "%s://%s:%d" (include "opentelemetry-collector.otlp.scheme" .) (include "opentelemetry-collector.fullname" .) (index .Values.global "opentelemetry-collector" "ports" "loki-http" "servicePort" | int )) -}}
{{- end -}}
{{- printf "%s/loki/api/v1/push" $baseUrl -}}
{{- end -}}

{{- define "opentelemetry-collector.otlp.tls.enabled" -}}
{{- eq (get (urlParse (include "opentelemetry-collector.otlp.http.url" .)) "scheme") "https" -}}
{{- end -}}

{{- define "opentelemetry-collector.otlp.http.url" -}}
{{- if .Values.global.otlp.overrideHttpURL -}}
    {{- print .Values.global.otlp.overrideHttpURL -}}
{{- else if .Values.global.ingress.site -}}
    {{- include "incloud.otel.http.url" . -}}
{{- else if not .Values.global.backend.enabled -}}
    {{- fail "A valid global.ingress.site or global.otlp.overrideHttpURL is required!" -}}
{{- else -}}
    {{- printf "%s://%s:%d" (include "opentelemetry-collector.otlp.scheme" .) (include "opentelemetry-collector.fullname" .) (index .Values.global "opentelemetry-collector" "ports" "otlp-http" "servicePort" | int ) -}}
{{- end -}}
{{- end -}}

{{- define "opentelemetry-collector.otlp.grpc.url" -}}
{{- if .Values.global.otlp.overrideGrpcURL -}}
    {{- print .Values.global.otlp.overrideGrpcURL -}}
{{- else if .Values.global.ingress.site -}}
    {{- include "incloud.otel.grpc.url" . -}}
{{- else if not .Values.global.backend.enabled -}}
    {{- fail "A valid global.ingress.site or global.otlp.overrideGrpcURL is required!" -}}
{{- else -}}
    {{- printf "%s:%d" (include "opentelemetry-collector.fullname" .) (index .Values.global "opentelemetry-collector" "ports" "otlp" "servicePort" | int ) -}}
{{- end -}}
{{- end -}}

{{- define "opentelemetry-collector.health.http.url" -}}
{{- $baseUrl := "" -}}
{{- if .Values.global.otlp.overrideHttpURL -}}
    {{- $baseUrl = .Values.global.otlp.overrideHttpURL -}}
{{- else if .Values.global.ingress.site -}}
    {{- $baseUrl = (printf "https://api-otel-http.%s" .Values.global.ingress.site) -}}
{{- else if not .Values.global.backend.enabled -}}
    {{- fail "A valid global.ingress.site or global.otlp.overrideHttpURL is required!" -}}
{{- else -}}
    {{- $baseUrl = (printf "%s://%s:%d" (include "opentelemetry-collector.otlp.scheme" .) (include "opentelemetry-collector.fullname" .) (index .Values.global "opentelemetry-collector" "ports" "health" "servicePort" | int )) -}}
{{- end -}}
{{- printf "%s/health" $baseUrl -}}
{{- end -}}

{{- define "opentelemetry-collector.datadogapm.base.http.url" -}}
{{- if .Values.global.datadogapm.overrideUrl -}}
    {{- .Values.global.datadogapm.overrideUrl -}}
{{- else if .Values.global.ingress.site -}}
    {{- include "incloud.otel.http.url" . -}}
{{- else if not .Values.global.backend.enabled -}}
    {{- fail "A valid global.ingress.site or global.datadogapm.overrideUrl is required!" -}}
{{- else -}}
    {{- printf "http://%s:%d" (include "opentelemetry-collector.fullname" .) (index .Values.global "opentelemetry-collector" "ports" "datadogapm" "servicePort" | int ) -}}
{{- end -}}
{{- end -}}

{{- define "opentelemetry-collector.datadogapm.traces.http.url" -}}
{{- printf "%s/v0.7/traces" (include "opentelemetry-collector.datadogapm.base.http.url" .) -}}
{{- end -}}