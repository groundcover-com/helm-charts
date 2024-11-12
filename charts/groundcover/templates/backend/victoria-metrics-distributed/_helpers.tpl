{{- define "victoria-metrics-distributed.cluster.availabilityZone" -}}
{{- index .Values.global.backend "victoria-metrics-distributed" "availabilityZone" }}
{{- end -}}