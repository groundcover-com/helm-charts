{{/*
Groundcover common labels
*/}}
{{- define "groundcover.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{/*
Backend chart name
*/}}
{{- define "backend.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "backend.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL helpers
*/}}
{{- define "postgresql.secretName" -}}
{{- if .Values.postgresql.auth.existingSecret -}}
{{- .Values.postgresql.auth.existingSecret -}}
{{- else if and .Values.global.cnpg.cluster.enabled .Values.global.cnpg.cluster.use -}}
{{- if .Values.global.cnpg.cluster.existingSecretName -}}
{{- .Values.global.cnpg.cluster.existingSecretName -}}
{{- else -}}
{{- printf "%s-app" (include "cnpg.fullname" .) -}}
{{- end -}}
{{- else -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}
{{- end -}}

{{- define "postgresql.primary.fullname" -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}

{{- define "cnpg.fullname" -}}
{{- printf "%s-cnpg-postgresql" .Release.Name -}}
{{- end -}}

{{- define "cnpg.existingSecretName" -}}
{{- if .Values.global.cnpg.cluster.existingSecretName -}}
{{- .Values.global.cnpg.cluster.existingSecretName -}}
{{- else if .Values.global.postgresql.auth.existingSecret -}}
{{- .Values.global.postgresql.auth.existingSecret -}}
{{- else -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}
{{- end -}}
