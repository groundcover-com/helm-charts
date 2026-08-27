{{- define "clickhouse.fullname" -}}
{{- printf "%s-clickhouse" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- /*
  Do NOT define "clickhouse.headlessServiceName" here: named templates are
  global, and this would shadow the Bitnami subchart's own definition of it,
  breaking the aliased standby instance's headless Service DNS.
*/ -}}

{{- define "clickhouse.database" -}}
{{-  print "groundcover" -}}
{{- end -}}

{{- define "clickhouse.username" -}}
{{-  print "default" -}}
{{- end -}}

{{- define "clickhouse.readerUsername" -}}
{{-  print "reader" -}}
{{- end -}}

{{- define "clickhouse.nativePort" -}}
{{- .Values.global.clickhouse.containerPorts.tcp | default "9000" -}}
{{- end -}}

{{- define "clickhouse.password" -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "clickhouse.secretName" .) | default dict) -}}
{{- if .Values.global.clickhouse.auth.password -}}
    {{- .Values.global.clickhouse.auth.password -}}
{{- else if $secret.data -}}
    {{- index $secret.data (include "clickhouse.secretKey" .) | b64dec -}}
{{- else if .Values.global.clickhouse.auth.existingSecret -}}
    {{- /* Externally-managed secret that isn't readable in this render (e.g. a
           dry-run, where lookup returns nothing). Never fall back to randAlphaNum
           here: with an existingSecret the chart isn't the source of truth, and a
           fresh random value each render churns every checksum/clickhouse-secret
           annotation and rolls the consumer pods on every reconcile. Return a
           stable token instead so the checksum is deterministic. */ -}}
    {{- printf "existing-%s" (include "clickhouse.secretName" .) -}}
{{- else -}}
    {{- randAlphaNum 16 -}}
{{- end -}}
{{- end -}}

{{/*
Dedicated read-only ClickHouse user the schema-managed dictionaries
authenticate with when global.clickhouse.dictionaryUser.enabled is set. Created
by db-manager on boot (CREATE USER IF NOT EXISTS + GRANT SELECT); its password
comes from the dedicated secret below, NOT the rotating admin secret, so admin
password rotations never invalidate dictionary credentials.
*/}}
{{- define "clickhouse.dictionaryUsername" -}}
{{- default "dictionary_reader" .Values.global.clickhouse.dictionaryUser.username -}}
{{- end -}}

{{- define "clickhouse.dictionaryUserSecretName" -}}
{{- default (printf "%s-dictionary-user" (include "clickhouse.fullname" .)) .Values.global.clickhouse.dictionaryUser.existingSecret -}}
{{- end -}}

{{- define "clickhouse.dictionaryUserSecretKey" -}}
{{- .Values.global.clickhouse.dictionaryUser.existingSecretKey -}}
{{- end -}}

{{- define "clickhouse.dictionaryUserPassword" -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "clickhouse.dictionaryUserSecretName" .) | default dict) -}}
{{- if $secret.data -}}
    {{- index $secret.data (include "clickhouse.dictionaryUserSecretKey" .) | b64dec -}}
{{- else -}}
    {{- randAlphaNum 24 -}}
{{- end -}}
{{- end -}}

{{- define "clickhouse.nativeEndpoint" -}}
{{-  printf "clickhouse://%s:%d" (include "clickhouse.fullname" .) (include "clickhouse.nativePort" . | int ) -}}
{{- end -}}

{{- define "clickhouse.httpEndpoint" -}}
{{-  printf "http://%s:%d" (include "clickhouse.fullname" .) (.Values.global.clickhouse.containerPorts.http | int ) -}}
{{- end -}}

{{- define "clickhouse.shard0Name" -}}
{{ printf "%s-shard0-0-external" (include "clickhouse.fullname" $) | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{- define "clickhouse.shard0HttpEndpoint" -}}
{{ printf "http://%s:%d" (include "clickhouse.shard0Name" $) (.Values.global.clickhouse.containerPorts.http | int ) }}
{{- end -}}

{{- define "clickhouse.proxyServiceName" -}}
{{- $name := "" -}}
{{- if .Values.clickhouseProxy -}}
{{- $name = (.Values.clickhouseProxy.service | default dict).name -}}
{{- end -}}
{{- if $name -}}
{{- if or (gt (len $name) 63) (not (regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" $name)) -}}
{{- fail (printf "clickhouseProxy.service.name %q must be a valid RFC 1123 DNS label (lowercase alphanumerics and '-', starting/ending with an alphanumeric, max 63 chars)" $name) -}}
{{- end -}}
{{- $name -}}
{{- else -}}
{{- printf "%s-clickhouse-proxy" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "clickhouse.readHost" -}}
{{- if (.Values.global.clickhouse.ha | default dict).enabled -}}
{{- include "clickhouse.proxyServiceName" . -}}
{{- else -}}
{{- include "clickhouse.fullname" . -}}
{{- end -}}
{{- end -}}

{{- define "clickhouse.readHostShard0" -}}
{{- if (.Values.global.clickhouse.ha | default dict).enabled -}}
{{- include "clickhouse.proxyServiceName" . -}}
{{- else -}}
{{- include "clickhouse.shard0Name" . | trim -}}
{{- end -}}
{{- end -}}

{{- define "clickhouse.extraShardsList" -}}
{{- if kindIs "slice" .Values.dbManager.extraShardsOverride }}
{{- .Values.dbManager.extraShardsOverride | toYaml | nindent 2 }}
{{- else }}
{{- $shards := $.Values.clickhouse.shards | int }}
{{- $list := list -}}
{{- range $shard, $e := until $shards }}
{{- if ne $e 0}}
{{- $item := printf "%s-shard%d-%d-external" (include "clickhouse.fullname" $) $shard 0 | trunc 63 | trimSuffix "-" }}
{{- $list = append $list $item }}
{{- end -}}
{{- end -}}
{{- $list | toYaml | nindent 2 }}
{{- end -}}
{{- end -}}

{{- define "clickhouse.opentelemetrySpanLogSetting" -}}
{{ if eq .Values.disableOpentelemetrySpanLog false }}
{{- else -}}
<opentelemetry_span_log remove="1"/>
{{- end -}}
{{- end -}}

