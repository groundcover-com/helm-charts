{{- define "vector.cluster.http.health.port" -}}
{{-  printf "8686"  -}}
{{- end -}}

{{- define "vector.cluster.http.health.endpoint" -}}
{{-  printf "%s://%s:%d" (include "vector.otlp.scheme" .) (include "vector.fullname" .) (include "vector.cluster.http.health.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.http.health.url" -}}
{{-  printf "%s/health" (include "vector.cluster.http.health.endpoint" .) -}}
{{- end -}}

{{- define "vector.incloud.http.health.url" -}}
{{-  printf "%s/ingest/v2/health" (include "incloud.ingestion.http.url" .) -}}
{{- end -}}

{{- define "vector.otlp.scheme" -}}
{{- ternary "https" "http" .Values.global.otlp.tls.enabled -}}
{{- end -}}

{{- define "vector.otlp.http.tls.enabled" -}}
{{- eq (get (urlParse (include "vector.logs.otlp.http.url" .)) "scheme") "https" -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.logs.port" -}}
{{-  printf "4317"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.logs.endpoint" -}}
{{-  printf "%s:%d" (include "vector.fullname" .) (include "vector.cluster.otlp.grpc.logs.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.logs.port" -}}
{{-  printf "4318"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.logs.endpoint" -}}
{{-  printf "%s://%s:%d" (include "vector.otlp.scheme" .) (include "vector.fullname" .) (include "vector.cluster.otlp.http.logs.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.logs.url" -}}
{{-  printf "%s/v1/logs" (include "vector.cluster.otlp.http.logs.endpoint" .) -}}
{{- end -}}

{{- define "vector.incloud.otlp.http.logs.url" -}}
{{-  printf "%s/ingest/v2/otlp/logs" (include "incloud.ingestion.http.url" .) -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.traces.port" -}}
{{-  printf "4327"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.traces.endpoint" -}}
{{-  printf "%s:%d" (include "vector.fullname" .) (include "vector.cluster.otlp.grpc.traces.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.traces.port" -}}
{{-  printf "4328"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.traces.endpoint" -}}
{{-  printf "%s://%s:%d" (include "vector.otlp.scheme" .) (include "vector.fullname" .) (include "vector.cluster.otlp.http.traces.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.traces-as-logs.url" -}}
{{-  printf "%s/v1/logs" (include "vector.cluster.otlp.http.traces.endpoint" .) -}}
{{- end -}}

{{- define "vector.incloud.otlp.http.traces-as-logs.url" -}}
{{-  printf "%s/ingest/v2/otlp/traces-as-logs" (include "incloud.ingestion.http.url" .) -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.custom.port" -}}
{{-  printf "4337"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.custom.endpoint" -}}
{{-  printf "%s:%d" (include "vector.fullname" .) (include "vector.cluster.otlp.grpc.custom.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.custom.port" -}}
{{-  printf "4338"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.custom.endpoint" -}}
{{-  printf "%s://%s:%d" (include "vector.otlp.scheme" .) (include "vector.fullname" .) (include "vector.cluster.otlp.http.custom.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.custom.url" -}}
{{-  printf "%s/v1/logs" (include "vector.cluster.otlp.http.custom.endpoint" .) -}}
{{- end -}}

{{- define "vector.incloud.otlp.http.custom.url" -}}
{{-  printf "%s/ingest/v2/otlp/custom" (include "incloud.ingestion.http.url" .) -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.monitors.port" -}}
{{-  printf "4347"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.monitors.endpoint" -}}
{{-  printf "%s:%d" (include "vector.fullname" .) (include "vector.cluster.otlp.grpc.monitors.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.monitors.port" -}}
{{-  printf "4348"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.monitors.endpoint" -}}
{{-  printf "%s://%s:%d" (include "vector.otlp.scheme" .) (include "vector.fullname" .) (include "vector.cluster.otlp.http.monitors.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.monitors.url" -}}
{{-  printf "%s/v1/logs" (include "vector.cluster.otlp.http.monitors.endpoint" .) -}}
{{- end -}}

{{- define "vector.tracesAsLogs.otlp.http.url" -}}
{{- if .Values.global.vector.tracesAsLogs.otlp.overrideHttpURL -}}
    {{- print .Values.global.vector.tracesAsLogs.otlp.overrideHttpURL -}}
{{- else if .Values.global.ingress.site -}}
    {{- include "vector.incloud.otlp.http.traces-as-logs.url" . -}}
{{- else if not .Values.global.backend.enabled -}}
    {{- fail "A valid global.ingress.site or global.vector.tracesAsLogs.otlp.overrideHttpURL is required!" -}}
{{- else -}}
    {{- include "vector.cluster.otlp.http.traces-as-logs.url" . -}}
{{- end -}}
{{- end -}}

{{- define "vector.logs.otlp.http.url" -}}
{{- if .Values.global.vector.logs.otlp.overrideHttpURL -}}
    {{- print .Values.global.vector.logs.otlp.overrideHttpURL -}}
{{- else if .Values.global.ingress.site -}}
    {{- include "vector.incloud.otlp.http.logs.url" . -}}
{{- else if not .Values.global.backend.enabled -}}
    {{- fail "A valid global.ingress.site or global.vector.logs.otlp.overrideHttpURL is required!" -}}
{{- else -}}
    {{- include "vector.cluster.otlp.http.logs.url" . -}}
{{- end -}}
{{- end -}}

{{- define "vector.custom.otlp.http.url" -}}
{{- if .Values.global.vector.custom.otlp.overrideHttpURL -}}
    {{- print .Values.global.vector.custom.otlp.overrideHttpURL -}}
{{- else if .Values.global.ingress.site -}}
    {{- include "vector.incloud.otlp.http.custom.url" . -}}
{{- else if not .Values.global.backend.enabled -}}
    {{- fail "A valid global.ingress.site or global.vector.custom.otlp.overrideHttpURL is required!" -}}
{{- else -}}
    {{- include "vector.cluster.otlp.http.custom.url" . -}}
{{- end -}}
{{- end -}}

{{- define "vector.health.http.url" -}}
{{- if .Values.global.vector.health.overrideHttpURL -}}
    {{- print .Values.global.vector.health.overrideHttpURL -}}
{{- else if .Values.global.ingress.site -}}
    {{- include "vector.incloud.http.health.url" . -}}
{{- else if not .Values.global.backend.enabled -}}
    {{- fail "A valid global.ingress.site or global.vector.health.overrideHttpURL is required!" -}}
{{- else -}}
    {{- include "vector.cluster.http.health.url" . -}}
{{- end -}}
{{- end -}}
