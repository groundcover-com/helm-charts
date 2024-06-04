{{- define "vector.otlpHttpPortLogs" -}}
{{-  printf "4318"  -}}
{{- end -}}

{{- define "vector.otlpLogsEndpoint" -}}
{{-  printf "http://%s:%d" (include "vector.fullname" .) (include "vector.otlpHttpPortLogs" . | int )  -}}
{{- end -}}

{{- define "vector.otlpHttpPortTraces" -}}
{{-  printf "4328"  -}}
{{- end -}}

{{- define "vector.otlpTracesEndpoint" -}}
{{-  printf "http://%s:%d" (include "vector.fullname" .) (include "vector.otlpHttpPortTraces" . | int )  -}}
{{- end -}}

