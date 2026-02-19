{{- define "agent-service.fullname" -}}
{{- printf "%s-agent-service" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "agent-service.values" -}}
{{- toYaml .Values.agentService -}}
{{- end -}}
