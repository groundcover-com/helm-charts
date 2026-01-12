{{- define "pdf-report-worker.fullname" -}}
{{- printf "%s-pdf-report-worker" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pdf-report-worker.configMapName" -}}
{{- printf "%s-pdf-report-worker-config" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
