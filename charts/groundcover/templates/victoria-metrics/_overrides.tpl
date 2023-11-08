{{- define "victoria-metrics.server.fullname" -}}
{{- printf "%s-victoria-metrics" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
