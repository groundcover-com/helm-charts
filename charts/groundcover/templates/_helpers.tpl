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
{{- define "groundcover.labels.partOf" -}}
{{- if .Values.global.groundcoverPartOf -}}
{{- .Values.global.groundcoverPartOf -}}
{{- else -}}
groundcover
{{- end -}}
{{- end }}

{{- define "groundcover.labels" -}}
app.kubernetes.io/part-of: '{{ include "groundcover.labels.partOf" . }}'
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
    {{- fail "A valid .Values.clusterId is required!" -}}
{{- end -}}
{{- end -}}

{{- define "groundcover.region" -}}
{{- .Values.region | default "undefined" }}
{{- end }}

{{- define "groundcover.env" -}}
{{- .Values.env | default "" }}
{{- end }}


{{- define "groundcover.shouldDropRunningNamespaces" -}}
{{ if not (quote .Values.shouldDropRunningNamespaces | empty)  }}
{{- .Values.shouldDropRunningNamespaces -}}
{{- else if .Values.global.airgap -}}
{{- printf "false"  -}}
{{- else -}}
{{- printf "true" }}
{{- end }}
{{- end }}


{{- define "groundcover.dropRunningNamespaceLogs" -}}
{{ if not (quote .Values.dropRunningNamespaceLogs | empty)  }}
{{- .Values.dropRunningNamespaceLogs -}}
{{- else if .Values.global.airgap -}}
{{- printf "false"  -}}
{{- else -}}
{{- printf "true" }}
{{- end }}
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

{{- define "incloud.ingestion.http.url" -}}
{{- printf "https://%s" .Values.global.ingress.site -}}
{{- end -}}

{{- define "incloud.ingestion.json.url" -}}
{{- printf "https://%s/ingest/v2/json" .Values.global.ingress.site -}}
{{- end -}}

{{- define "incloud.ingestion.otlp.health.url" -}}
{{-  printf "%s/ingest/v2/health" (include "incloud.ingestion.http.url" .) -}}
{{- end -}}

{{- define "incloud.ingestion.otlp.http.logs.url" -}}
{{-  printf "%s/ingest/v2/otlp/logs" (include "incloud.ingestion.http.url" .) -}}
{{- end -}}

{{- define "incloud.ingestion.otlp.http.traces-as-logs.url" -}}
{{-  printf "%s/ingest/v2/otlp/traces-as-logs" (include "incloud.ingestion.http.url" .) -}}
{{- end -}}

{{- define "incloud.ingestion.otlp.http.custom.url" -}}
{{-  printf "%s/ingest/v2/otlp/custom" (include "incloud.ingestion.http.url" .) -}}
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

{{- define "telemetry.traces.otlpUrl" }}
    {{- .Values.global.telemetry.traces.otlpUrl -}}
{{- end -}}

{{- define "telemetry.traces.zipkinUrl" }}
    {{- .Values.global.telemetry.traces.zipkinUrl -}}
{{- end -}}

{{- define "db-manager.ready.http.url" -}}
{{- print "http://db-manager:8888/writer-ready" -}}
{{- end -}}

{{- define "ingestion.traces.otlp.http.url" -}}
{{- if (include  "vector.useVector" .) -}}
    {{ include "vector.tracesAsLogs.otlp.http.url" . }}
{{- else if .Values.global.ingress.site -}}
    {{ include "incloud.ingestion.otlp.http.traces-as-logs.url" . }}
{{- else -}}
    {{ include "opentelemetry-collector.otlptraces.http.url" . }}
{{- end -}}
{{- end -}}

{{- define "ingestion.logs.otlp.http.url" -}}
{{- if (include  "vector.useVector" .) -}}
    {{ include "vector.logs.otlp.http.url" . }}
{{- else if .Values.global.ingress.site -}}
    {{ include "incloud.ingestion.otlp.http.logs.url" . }}
{{- else -}}
    {{ include "opentelemetry-collector.otlplogs.http.url" . }}
{{- end -}}
{{- end -}}

{{- define "ingestion.custom.otlp.http.url" -}}
{{- if (include  "vector.useVector" .) -}}
    {{ include "vector.custom.otlp.http.url" . }}
{{- else if .Values.global.ingress.site -}}
    {{ include "incloud.ingestion.otlp.http.custom.url" . }}
{{- else -}}
    {{ include "opentelemetry-collector.otlplogs.http.url" . }}
{{- end -}}
{{- end -}}

{{- define "ingestion.health.http.url" -}}
{{- if (include  "vector.useVector" .) -}}
    {{ include "vector.health.http.url" . }}
{{- else if .Values.global.ingress.site -}}
    {{ include "incloud.ingestion.otlp.health.url" . }}
{{- else -}}
    {{ include "opentelemetry-collector.health.http.url" . }}
{{- end -}}
{{- end -}}

/* monitors ignore ingress config, always send to local  */
{{- define "ingestion.monitors.otlp.http.url" -}}
{{- if .Values.global.vector.enabled -}}
    {{ include "vector.cluster.otlp.http.monitors.url" . }}
{{- else -}}
    {{ include "opentelemetry-collector.otlplogs.http.url" . }}
{{- end -}}
{{- end -}}

{{- define "ingestion.otlp.tls.enabled" -}}
{{- if .Values.global.vector.enabled -}}
    {{ include "vector.otlp.http.tls.enabled" . }}
{{- else -}}
    {{ include "opentelemetry-collector.otlp.tls.enabled" . }}
{{- end -}}
{{- end -}}

{{/*
  Helper for spreading helm love.

  Examples:
  {{- include "groundcover.debug.dump" (list "a" 1 "x" (dict "x1" nil)) }}
  {{- include "groundcover.debug.dump" $ }}
  {{- include "groundcover.debug.dump" . }}

  & co..
*/}}
{{- define "groundcover.debug.dump" -}}
{{- . | mustToPrettyJson | printf "\n\n%s" | fail }}
{{- end -}}

{{/*
Create the name of the agent priority class to use
*/}}
{{- define "groundcover.agentPriorityClass" -}}
{{- if .Values.agent.priorityClass.fullname }}
{{- .Values.agent.priorityClass.fullname }}
{{- else }}
{{- include "groundcover.fullname" . }}-sensor-high-priority
{{- end }}
{{- end }}