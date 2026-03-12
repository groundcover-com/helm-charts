{{- define "comm-hub.fullname" -}}
{{- printf "%s-comm-hub" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Comm Hub config map name
*/}}
{{- define "comm-hub.configMapName" -}}
{{- printf "%s-comm-hub-config" .Release.Name -}}
{{- end -}}
