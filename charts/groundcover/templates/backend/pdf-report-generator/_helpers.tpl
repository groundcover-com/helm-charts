{{- define "pdf-report-generator.fullname" -}}
{{- printf "%s-pdf-report-generator" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
