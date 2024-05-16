{{- define "vector.otlpHttpPort" -}}
{{-  printf "4318"  -}}
{{- end -}}

{{- define "vector.otlpEndpoint" -}}
{{-  printf "http://%s:%d" (include "vector.fullname" .) (include "vector.otlpHttpPort" . | int )  -}}
{{- end -}}
