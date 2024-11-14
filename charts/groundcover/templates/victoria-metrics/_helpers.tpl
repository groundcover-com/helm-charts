{{- define "victoria-metrics.read.http.scheme" -}}
  {{- $scheme := "http" -}}
  {{- if .Values.global.metrics.overrideUrl -}}
    {{- $overrideUrl = .Values.global.metrics.overrideUrl -}}
    {{- $parsedUrl := (urlParse $overrideUrl) -}}
    {{- $scheme = $parsedUrl.scheme -}}
  {{- else if and .Values.global.metrics.read .Values.global.metrics.read.overrideScheme -}}
    {{- $scheme = .Values.global.metrics.read.overrideScheme -}}
  {{- end -}}

  {{- $scheme -}}
{{- end -}}

{{- define "victoria-metrics.read.http.host" -}}
  {{- $host := "" -}}
  {{- if .Values.global.metrics.overrideUrl -}}
    {{- $overrideUrl = .Values.global.metrics.overrideUrl -}}
    {{- $parsedUrl := (urlParse $overrideUrl) -}}
    {{- $hostParts := (splitList ":" $parsedUrl.host) -}}
    {{- $host = (index $hostParts 0) -}}
  {{- else if and .Values.global.metrics.read .Values.global.metrics.read.overrideHost -}}
    {{- $host = .Values.global.metrics.read.overrideHost -}}
  {{- end -}}

  {{- if $host -}}
    {{- $host -}}
  {{- else if index .Values.global.backend "victoria-metrics-distributed" "enabled" -}}
    {{- printf "vmauth-%s" (include "victoria-metrics-distributed.vmauthQueryGlobalName" .) -}}
  {{- else -}}
    {{- printf "%s" (include "victoria-metrics.server.fullname" .) -}}
  {{- end -}}
{{- end -}}

{{- define "victoria-metrics.read.http.port" -}}
  {{- $port := "" -}}
  {{- if .Values.global.metrics.overrideUrl -}}
    {{- $overrideUrl = .Values.global.metrics.overrideUrl -}}
    {{- $parsedUrl := (urlParse $overrideUrl) -}}
    {{- $hostParts := (splitList ":" $parsedUrl.host) -}}
    {{- $port = (index $hostParts 1) -}}
  {{- else if and .Values.global.metrics.read .Values.global.metrics.read.overridePort -}}
    {{- $port = .Values.global.metrics.read.overridePort -}}
  {{- end -}}

  {{- if $port -}}
    {{- $port -}}
  {{- else if index .Values.global.backend "victoria-metrics-distributed" "enabled" -}}
    {{- printf "8427" -}}
  {{- else -}}
    {{- printf "%d" (index .Values.global "victoria-metrics" "service" "servicePort" | int ) -}}
  {{- end -}}
{{- end -}}

{{- define "victoria-metrics.read.http.path" -}}
  {{- $path := "-" -}}
  {{- if .Values.global.metrics.overrideUrl -}}
    {{- $overrideUrl = .Values.global.metrics.overrideUrl -}}
    {{- $parsedUrl := (urlParse $overrideUrl) -}}
    {{- $path = $parsedUrl.path -}}
  {{- else if and .Values.global.metrics.read -}}
    {{- if ne .Values.global.metrics.read.overridePath nil -}}
      {{- $path = .Values.global.metrics.read.overridePath -}}
    {{- end -}}
  {{- end -}}

  {{- if (ne $path "-") -}}
    {{- $path -}}
  {{- else if index .Values.global.backend "victoria-metrics-distributed" "enabled" -}}
    {{- printf "select/0/prometheus" -}}
  {{- else -}}
    {{- printf "" -}}
  {{- end -}}
{{- end -}}

{{- define "victoria-metrics.write.http.scheme" -}}
  {{- $scheme := "http" -}}
  {{- if .Values.global.metrics.overrideUrl -}}
    {{- $overrideUrl = .Values.global.metrics.overrideUrl -}}
    {{- $parsedUrl := (urlParse $overrideUrl) -}}
    {{- $scheme = $parsedUrl.scheme -}}
  {{- else if and .Values.global.metrics.write .Values.global.metrics.write.overrideScheme -}}
    {{- $scheme = .Values.global.metrics.write.overrideScheme -}}
  {{- end -}}

  {{- $scheme -}}
{{- end -}}

{{- define "victoria-metrics.write.http.host" -}}
  {{- $host := "" -}}
  {{- if .Values.global.metrics.overrideUrl -}}
    {{- $overrideUrl = .Values.global.metrics.overrideUrl -}}
    {{- $parsedUrl := (urlParse $overrideUrl) -}}
    {{- $hostParts := (splitList ":" $parsedUrl.host) -}}
    {{- $host = (index $hostParts 0) -}}
  {{- else if and .Values.global.metrics.write .Values.global.metrics.write.overrideHost -}}
    {{- $host = .Values.global.metrics.write.overrideHost -}}
  {{- end -}}

  {{- if $host -}}
    {{- $host -}}
  {{- else if index .Values.global.backend "victoria-metrics-distributed" "enabled" -}}
    {{- printf "vmauth-%s" (include "victoria-metrics-distributed.vmauthIngestGlobalName" .) -}}
  {{- else -}}
    {{- printf "%s" (include "victoria-metrics.server.fullname" .) -}}
  {{- end -}}
{{- end -}}

{{- define "victoria-metrics.write.http.port" -}}
  {{- $port := "" -}}
  {{- if .Values.global.metrics.overrideUrl -}}
    {{- $overrideUrl = .Values.global.metrics.overrideUrl -}}
    {{- $parsedUrl := (urlParse $overrideUrl) -}}
    {{- $hostParts := (splitList ":" $parsedUrl.host) -}}
    {{- $port = (index $hostParts 1) -}}
  {{- else if and .Values.global.metrics.write .Values.global.metrics.write.overridePort -}}
    {{- $port = .Values.global.metrics.write.overridePort -}}
  {{- end -}}

  {{- if $port -}}
    {{- $port -}}
  {{- else if index .Values.global.backend "victoria-metrics-distributed" "enabled" -}}
    {{- printf "8427" -}}
  {{- else -}}
    {{- printf "%d" (index .Values.global "victoria-metrics" "service" "servicePort" | int ) -}}
  {{- end -}}
{{- end -}}

{{- define "victoria-metrics.write.http.path" -}}
  {{- $path := "-" -}}
  {{- if .Values.global.metrics.overrideUrl -}}
    {{- $overrideUrl = .Values.global.metrics.overrideUrl -}}
    {{- $parsedUrl := (urlParse $overrideUrl) -}}
    {{- $path = $parsedUrl.path -}}
  {{- else if and .Values.global.metrics.write -}}
    {{- if ne .Values.global.metrics.write.overridePath nil -}}
      {{- $path = .Values.global.metrics.write.overridePath -}}
    {{- end -}}
  {{- end -}}

  {{- if (ne $path "-") -}}
    {{- $path -}}
  {{- else if index .Values.global.backend "victoria-metrics-distributed" "enabled" -}}
    {{- printf "prometheus/api/v1/write" -}}
  {{- else -}}
    {{- printf "api/v1/write" -}}
  {{- end -}}
{{- end -}}

{{/*
READ: Used by monitors-manager, portal
*/}}
{{- define "victoria-metrics.read.http.url" -}}
{{- (printf "%s://%s:%s/%s" (include "victoria-metrics.read.http.scheme" .) (include "victoria-metrics.read.http.host" .) (include "victoria-metrics.read.http.port" .) (include "victoria-metrics.read.http.path" .)) | trimSuffix "/" -}}
{{- end -}}

{{/*
READ: Used by kong for exposing access point to external grafana
TODO: Fix for VMCluster
*/}}
{{- define "victoria-metrics.service.fullname" -}}
{{- printf "%s-victoria-metrics" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
WRITE: Used by metrics-ingestor and custom-metrics
*/}}
{{- define "victoria-metrics.write.http.url" -}}
{{- if or .Values.global.backend.enabled .Values.global.metrics.overrideUrl -}}
    {{- (printf "%s://%s:%s/%s" (include "victoria-metrics.write.http.scheme" .) (include "victoria-metrics.write.http.host" .) (include "victoria-metrics.write.http.port" .) (include "victoria-metrics.write.http.path" .)) | trimSuffix "/" -}}
{{- else if .Values.global.ingress.site -}}
    {{- printf "%s/api/v1/write" (include "incloud.metrics.http.url" .) -}}
{{- else -}}
    {{- fail "A valid global.ingress.site or global.metrics.overrideUrl is required" -}}
{{- end -}}
{{- end -}}
