{{/* In-cluster ingestor OTLP/HTTP base URL, shared by both workers (as comm-hub and dispatch-center target it for traces). */}}
{{- define "autoinfra.otlpEndpoint" -}}
{{- printf "http://%s:%s" (include "ingestor.fullname" .) (include "ingestor.otlphttp.port" .) -}}
{{- end -}}
