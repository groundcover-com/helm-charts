{{/*
Expand the name of the chart.
*/}}
{{- define "groundcover.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "groundcover.fullname" -}}
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
{{- define "groundcover.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "groundcover.labels" -}}
helm.sh/chart: {{ include "groundcover.chart" . }}
{{ include "groundcover.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "groundcover.selectorLabels" -}}
app.kubernetes.io/name: {{ include "groundcover.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "groundcover.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "groundcover.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get cluster_id from values or generate random one
*/}}
{{- define "groundcover.clusterId" -}}
{{- .Values.clusterId | default (printf "%s-%s" "Cluster" (randAlphaNum 7)) }}
{{- end }}

{{- define "groundcover.region" -}}
{{- .Values.region | default "undefined" }}
{{- end }}

{{- define "grafana.name" -}}
{{- default "grafana" .Values.grafana.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "groundcover.apikeySecretName" -}}
{{- default "api-key" .Values.global.groundcoverPredefinedTokenSecret.secretName -}}
{{- end -}}

{{- define "groundcover.apikeySecretKey" -}}
{{- default "API_KEY" .Values.global.groundcoverPredefinedTokenSecret.secretKey -}}
{{- end -}}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "promscale.fullname" -}}
{{- if .Values.promscale.fullnameOverride -}}
{{- .Values.promscale.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.promscale.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "promscale.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Allow the release namespace to be overridden
*/}}
{{- define "promscale.namespace" -}}
  {{- if .Values.promscale.namespaceOverride -}}
    {{- .Values.promscale.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{- define "promscale_secrets_certificate" -}}
{{ printf "%s-certificate" (include "promscale.fullname" .) }}
{{- end -}}