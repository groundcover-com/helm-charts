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
app.kubernetes.io/part-of: groundcover
{{ with .Values.global.groundcoverLabels }} 
{{- toYaml . }}
{{- end }}
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


{{- define "groundcover.config.secretName" -}}
{{- print "groundcover-config" -}}
{{- end -}}

{{/*
Get cluster_id from values or generate random one
*/}}
{{- define "groundcover.clusterId" -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "groundcover.config.secretName" .) | default dict) -}}
{{- if .Values.clusterId -}}
    {{- .Values.clusterId -}}
{{- else if $secret -}}
    {{- index $secret "data" "GC_CLUSTER_ID" | b64dec -}}
{{- else -}}
    {{- printf "Cluster-%s" (randAlphaNum 7) -}}
{{- end -}}
{{- end -}}

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

{{- define "agent.tracy.enabled" }}
{{- eq .Values.mode "legacy" -}}
{{- end -}}

{{- define "imagePullSecrets" }}
{{- default .Values.global.imagePullSecrets .Values.imagePullSecrets | toJson -}}
{{- end -}}}}

{{- define "incloud.otel.http.url" -}}
{{- printf "https://api-otel-http.%s" .Values.global.ingress.site -}}
{{- end -}}

{{- define "incloud.metrics.http.url" -}}
{{- printf "https://metrics-http.%s" .Values.global.ingress.site -}}
{{- end -}}

{{- define "incloud.otel.grpc.url" -}}
{{- printf "api-otel-grpc.%s:443" .Values.global.ingress.site -}}
{{- end -}}

{{- define "telemetry.enabled" }}
{{- if .Values.metrics -}}
    {{- .Values.metrics.enabled -}}
{{- else -}}
    {{- .Values.global.telemetry.enabled -}}
{{- end -}}
{{- end -}}

{{- define "telemetry.metrics.url" }}
{{- if and .Values.metrics .Values.metrics.host -}}
    {{- printf "https://%s/api/v1/write" .Values.metrics.host -}}
{{- else -}}
    {{- .Values.global.telemetry.metrics.url -}}
{{- end -}}
{{- end -}}

{{- define "telemetry.metrics.base.url" }}
{{- $url := urlParse (include "telemetry.metrics.url" .) -}}
{{- printf "%s://%s" (get $url "scheme") (get $url "host") -}}
{{- end -}}

{{- define "telemetry.logs.url" }}
{{- if and .Values.logging .Values.logging.host -}}
    {{- printf "https://%s/v1/logs" .Values.logging.host -}}
{{- else -}}
    {{- .Values.global.telemetry.logs.url -}}
{{- end -}}
{{- end -}}

{{- define "db-manager.ready.http.url" -}}
{{- print "http://db-manager:8888/writer-ready" -}}
{{- end -}}