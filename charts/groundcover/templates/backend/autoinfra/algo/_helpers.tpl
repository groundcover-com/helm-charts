{{- define "autoinfra-algo.fullname" -}}
{{- printf "%s-autoinfra-algo" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "autoinfra-algo.configMapName" -}}
{{- printf "%s-config" (include "autoinfra-algo.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "autoinfra-algo.labels" -}}
{{- include "groundcover.labels" . }}
app: autoinfra-algo
app.kubernetes.io/name: autoinfra-algo
{{- end -}}
