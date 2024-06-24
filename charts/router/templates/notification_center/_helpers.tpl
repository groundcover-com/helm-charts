{{/*
Expand the name of the chart.
*/}}
{{- define "notification-center.name" -}}
{{- default "notification-center" .Values.notifications.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "notification-center.fullname" -}}
{{- if .Values.notifications.fullnameOverride }}
{{- .Values.notifications.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "notification-center" .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "notification-center.labels" -}}
{{ include "notification-center.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: groundcover
{{ with .Values.notifications.additionalLabels }} 
{{- toYaml . -}}
{{- end }}
{{ with .Values.global.groundcoverLabels }} 
{{- toYaml . -}}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "notification-center.selectorLabels" -}}
app.kubernetes.io/name: {{ include "notification-center.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "notification-center.serviceAccountName" -}}
{{- if .Values.notifications.serviceAccount.create }}
{{- default (include "notification-center.fullname" .) .Values.notifications.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.notifications.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "notification-center.imagePullSecrets" -}}
{{- .Values.notifications.imagePullSecrets | toJson -}}
{{- end -}}

{{- define "notification-center.service.name" -}}
{{ print "notification-center" }}
{{- end -}}

{{- define "notification-center.image" -}}
{{ printf "%s/%s:%s" .Values.notifications.image.registry .Values.notifications.image.repository (default .Chart.AppVersion .Values.notifications.image.tag)}}
{{- end -}}