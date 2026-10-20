{{- define "autoinfra-config.fullname" -}}
{{- printf "%s-autoinfra-config" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
