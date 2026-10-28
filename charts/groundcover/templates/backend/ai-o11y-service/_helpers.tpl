{{- define "ai-o11y-service.fullname" -}}
{{- printf "%s-ai-o11y-service" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
