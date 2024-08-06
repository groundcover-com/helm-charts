{{/*
Expand the name of the chart.
*/}}
{{- define "incloud-ingress.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "incloud-ingress.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "incloud-ingress.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "incloud-ingress.labels" -}}
helm.sh/chart: {{ include "incloud-ingress.chart" . }}
{{ include "incloud-ingress.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "incloud-ingress.certificate.name" -}}
{{ printf "%s-%s" .Release.Name .Values.ingress.tls.certificate.name }}
{{- end }}

{{- define "incloud-ingress.certificate.dnsNames" -}}
- {{ .Values.global.ingress.site }}
- {{ printf "status.%s" .Values.global.ingress.site }}
- {{ printf "metrics-http.%s" .Values.global.ingress.site }}
- {{ printf "api-otel-http.%s" .Values.global.ingress.site }}
- {{ printf "api-otel-grpc.%s" .Values.global.ingress.site }}
{{- end }}
