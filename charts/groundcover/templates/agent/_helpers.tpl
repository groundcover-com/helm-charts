{{- define "alligator.fullname" -}}
{{- printf "%s-alligator" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
