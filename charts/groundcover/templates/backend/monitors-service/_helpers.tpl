{{- define "monitors-service.fullname" -}}
{{- printf "%s-monitors-service" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
