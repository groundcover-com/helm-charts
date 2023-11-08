{{/*
Create the name of the service account to use
*/}}
{{- define "kube-state-metrics.serviceAccountName" -}}
{{- if index .Values.global "kube-state-metrics" "serviceAccount" "create" -}}
    {{ default (include "kube-state-metrics.fullname" .) (index .Values.global "kube-state-metrics" "serviceAccount" "name") }}
{{- else -}}
    {{ default "default" (index .Values.global "kube-state-metrics" "serviceAccount" "name") }}
{{- end -}}
{{- end -}}
