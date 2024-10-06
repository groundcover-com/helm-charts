{{- define "sensor.fullname" -}}
    {{- printf "%s-sensor" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "alligator.fullname" -}}
    {{- printf "%s-alligator" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}