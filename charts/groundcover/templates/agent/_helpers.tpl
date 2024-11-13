{{- define "sensor.fullname" -}}
    {{- printf "%s-sensor" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "sensor.metric-ingestor-hostname" -}}
    {{- printf "%s-metric-ingestor" (include "sensor.fullname" .) -}}
{{- end -}}
{{- define "alligator.fullname" -}}
    {{- printf "%s-alligator" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}