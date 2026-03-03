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

{{- define "kube-state-metrics.url" -}}
    {{- printf "http://%s-kube-state-metrics:8080/metrics" .Release.Name -}}
{{- end -}}

{{/*
Override kube-state-metrics labels to include global.groundcoverLabels
*/}}
{{- define "kube-state-metrics.labels" }}
helm.sh/chart: {{ template "kube-state-metrics.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: metrics
app.kubernetes.io/part-of: {{ template "kube-state-metrics.name" . }}
{{- include "kube-state-metrics.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- if .Values.customLabels }}
{{ tpl (toYaml .Values.customLabels) . }}
{{- end }}
{{- with .Values.global.groundcoverLabels }}
{{ toYaml . }}
{{- end }}
{{- if .Values.releaseLabel }}
release: {{ .Release.Name }}
{{- end }}
{{- end }}