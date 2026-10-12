{{- define "workload-recommendations.fullname" -}}
{{- printf "%s-workload-recommendations" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "workload-recommendations.configMapName" -}}
{{- printf "%s-config" (include "workload-recommendations.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "workload-recommendations.labels" -}}
{{- include "groundcover.labels" . }}
app: workload-recommendations
app.kubernetes.io/name: workload-recommendations
{{- end -}}
