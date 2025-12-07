{{- define "dispatch-center.fullname" -}}
{{- printf "%s-dispatch-center" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Dispatch Center config map name
*/}}
{{- define "dispatch-center.configMapName" -}}
{{- printf "%s-dispatch-center-config" .Release.Name -}}
{{- end -}}

