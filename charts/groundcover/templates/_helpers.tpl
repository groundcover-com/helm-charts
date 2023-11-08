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

{{- define "agent.monitoring.port" -}}
{{- default 9102 (.Values.agent.monitoring).port -}}
{{- end -}}

{{- define "groundcover.apikeySecretName" -}}
{{- default "api-key" .Values.global.groundcoverPredefinedTokenSecret.secretName -}}
{{- end -}}

{{- define "groundcover.apikeySecretKey" -}}
{{- default "API_KEY" .Values.global.groundcoverPredefinedTokenSecret.secretKey -}}
{{- end -}}

{{- define "promscale.promURL" -}}
{{- default ( printf "https://groundcover-promscale-connector:%d"  ( .Values.promscale.prometheus.port | int ) ) .Values.promscale.overridePromURL  -}}
{{- end -}}

{{- define "promscale.otelURL" -}}
{{- default ( printf "groundcover-promscale-connector:%d"  ( .Values.promscale.openTelemetry.port | int ) ) .Values.promscale.overrideOtelURL  -}}
{{- end -}}

{{- define "loki.url" -}}
{{- default ( printf "http://groundcover-loki:%d"  ( .Values.loki.service.port | int ) ) .Values.loki.overrideURL  -}}
{{- end -}}

{{- define "shepherd.http_scheme"}}
{{- if and .Values.shepherd.config.ingestor.TLSCertFile .Values.shepherd.config.ingestor.TLSKeyFile }}
{{- printf "%s" "https" -}}
{{- else}}
{{- printf "%s" "http" -}}
{{- end }}
{{- end -}}

{{- define "shepherd.grpc" -}}
{{- index .Values "shepherd" "overrideGrpcURL" | default ( printf "shepherd:%d"  ( .Values.shepherd.service.grpcPort | int ) ) -}}
{{- end -}}

{{- define "shepherd.http" -}}
{{- index .Values "shepherd" "overrideHttpURL" | default ( printf "%s://shepherd:%d"  ( include "shepherd.http_scheme" . ) ( .Values.shepherd.service.httpPort | int ) ) -}}
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

{{/*
disable http tracing in tracy if experimental is enabled
*/}}
{{- define "tracy.enable_http" -}}
  {{- if .Values.agent.experimental -}}
    {{- false -}}
  {{- else -}}
    {{- true -}}
  {{- end -}}
{{- end -}}

{{/*
disable redis tracing in tracy if experimental is enabled
*/}}
{{- define "tracy.enable_redis" -}}
  {{- if .Values.agent.experimental -}}
    {{- false -}}
  {{- else -}}
    {{- true -}}
  {{- end -}}
{{- end -}}

{{/*
disable dns tracing in tracy if experimental is enabled
*/}}
{{- define "tracy.enable_dns" -}}
  {{- if .Values.agent.experimental -}}
    {{- false -}}
  {{- else -}}
    {{- true -}}
  {{- end -}}
{{- end -}}

{{- define "imagePullSecrets" }}
{{- default .Values.global.imagePullSecrets .Values.imagePullSecrets | toJson -}}
{{- end -}}}}

{{- define "shepherd.tls_enabled"}}
{{- if and .Values.shepherd.config.ingestor.TLSCertFile .Values.shepherd.config.ingestor.TLSKeyFile }}
{{- true -}}
{{- else}}
{{- false -}}
{{- end }}
{{- end -}}