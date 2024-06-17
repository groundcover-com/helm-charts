{{- define "vector.otlp.scheme" -}}
{{- ternary "https" "http" .Values.global.otlp.tls.enabled -}}
{{- end -}}

{{- define "vector.otlpGrpcPortLogs" -}}
{{-  printf "4317"  -}}
{{- end -}}

{{- define "vector.otlpGrpcLogsEndpoint" -}}
{{-  printf "%s:%d" (include "vector.fullname" .) (include "vector.otlpGrpcPortLogs" . | int )  -}}
{{- end -}}

{{- define "vector.otlpHttpPortLogs" -}}
{{-  printf "4318"  -}}
{{- end -}}

{{- define "vector.otlpHttpLogsEndpoint" -}}
{{-  printf "%s://%s:%d" (include "vector.otlp.scheme" .) (include "vector.fullname" .) (include "vector.otlpHttpPortLogs" . | int )  -}}
{{- end -}}

{{- define "vector.otlpGrpcPortTraces" -}}
{{-  printf "4327"  -}}
{{- end -}}

{{- define "vector.otlpGrpcTracesEndpoint" -}}
{{-  printf "%s:%d" (include "vector.fullname" .) (include "vector.otlpGrpcPortTraces" . | int )  -}}
{{- end -}}

{{- define "vector.otlpHttpPortTraces" -}}
{{-  printf "4328"  -}}
{{- end -}}

{{- define "vector.otlpHttpTracesEndpoint" -}}
{{-  printf "%s://%s:%d" (include "vector.otlp.scheme" .) (include "vector.fullname" .) (include "vector.otlpHttpPortTraces" . | int )  -}}
{{- end -}}

{{- define "vector.otlpGrpcPortCustom" -}}
{{-  printf "4337"  -}}
{{- end -}}

{{- define "vector.otlpGrpcCustomEndpoint" -}}
{{-  printf "%s:%d" (include "vector.fullname" .) (include "vector.otlpGrpcPortCustom" . | int )  -}}
{{- end -}}

{{- define "vector.otlpHttpPortCustom" -}}
{{-  printf "4338"  -}}
{{- end -}}

{{- define "vector.otlpHttpCustomEndpoint" -}}
{{-  printf "%s://%s:%d" (include "vector.otlp.scheme" .) (include "vector.fullname" .) (include "vector.otlpHttpPortCustom" . | int )  -}}
{{- end -}}

{{- define "vector.otlpGrpcPortMonitors" -}}
{{-  printf "4347"  -}}
{{- end -}}

{{- define "vector.otlpGrpcMonitorsEndpoint" -}}
{{-  printf "%s:%d" (include "vector.fullname" .) (include "vector.otlpGrpcPortMonitors" . | int )  -}}
{{- end -}}

{{- define "vector.otlpHttpPortMonitors" -}}
{{-  printf "4348"  -}}
{{- end -}}

{{- define "vector.otlpHttpMonitorsEndpoint" -}}
{{-  printf "%s://%s:%d" (include "vector.otlp.scheme" .) (include "vector.fullname" .) (include "vector.otlpHttpPortMonitors" . | int )  -}}
{{- end -}}
