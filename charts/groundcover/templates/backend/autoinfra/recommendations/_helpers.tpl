{{- define "autoinfra-recommendations.fullname" -}}
{{- printf "%s-autoinfra-recommendations" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "autoinfra-recommendations.configMapName" -}}
{{- printf "%s-config" (include "autoinfra-recommendations.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "autoinfra-recommendations.labels" -}}
{{- include "groundcover.labels" . }}
app: autoinfra-recommendations
app.kubernetes.io/name: autoinfra-recommendations
{{- end -}}
