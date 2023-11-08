{{- define "grafana.fullname" -}}
{{- printf "%s-grafana" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account
*/}}
{{- define "grafana.serviceAccountName" -}}
{{- if .Values.global.grafana.serviceAccount.create }}
{{- default (include "grafana.fullname" .) .Values.global.grafana.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.global.grafana.serviceAccount.name }}
{{- end }}
{{- end }}
