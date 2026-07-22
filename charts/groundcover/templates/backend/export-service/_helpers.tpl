{{- define "export-service.fullname" -}}
{{- printf "%s-export-service" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
