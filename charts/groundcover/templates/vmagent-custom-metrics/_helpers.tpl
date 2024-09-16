{{- define "custom-metrics.server.fullname" -}}
{{- printf "%s-custom-metrics" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "custom-metrics.base.http.url" -}}
    {{- printf "http://%s:%d" (include "custom-metrics.server.fullname" .) (8429) -}}
{{- end -}}

{{- define "custom-metrics.write.http.url" -}}
{{- printf "%s/api/v1/write" (include "custom-metrics.base.http.url" .) -}}
{{- end -}}
