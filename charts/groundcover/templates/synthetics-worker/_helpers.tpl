{{- define "synthetics-worker.fullname" -}}
synthetics-worker
{{- end -}}

{{- define "synthetics-worker.port" -}}
3000
{{- end -}}

{{- define "synthetics-worker.url" -}}
{{- printf "http://%s:%s" (include "synthetics-worker.fullname" .) (include "synthetics-worker.port" .) -}}
{{- end -}}

