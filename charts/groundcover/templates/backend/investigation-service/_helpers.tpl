{{- define "investigation-service.fullname" -}}
{{- printf "%s-investigation-service" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "investigation-service.configMapName" -}}
{{- printf "%s-investigation-service-config" .Release.Name -}}
{{- end -}}

{{- define "investigation-service.temporalHost" -}}
{{- .Values.investigationService.temporal.host | default (printf "%s-temporal-frontend" .Release.Name) -}}
{{- end -}}
