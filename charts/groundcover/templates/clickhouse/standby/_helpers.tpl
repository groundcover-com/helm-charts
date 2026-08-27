{{- define "clickhouse.standby.fullname" -}}
{{- printf "%s-clickhouse-standby" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "clickhouse.standby.headlessServiceName" -}}
{{- printf "%s-headless" (include "clickhouse.standby.fullname" .) -}}
{{- end -}}

{{- define "clickhouse.standby.shard0Name" -}}
{{ printf "%s-shard0-0-external" (include "clickhouse.standby.fullname" $) | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{- define "clickhouse.standby.shard0HttpEndpoint" -}}
{{ printf "http://%s:%d" (include "clickhouse.standby.shard0Name" $) (.Values.global.clickhouse.containerPorts.http | int) }}
{{- end -}}

{{- define "clickhouse.standby.nativeEndpoint" -}}
{{- printf "clickhouse://%s:%d" (include "clickhouse.standby.fullname" .) (.Values.global.clickhouse.containerPorts.tcp | int) -}}
{{- end -}}

{{- define "clickhouse.standby.httpEndpoint" -}}
{{- printf "http://%s:%d" (include "clickhouse.standby.fullname" .) (.Values.global.clickhouse.containerPorts.http | int) -}}
{{- end -}}

{{- define "clickhouse.standby.extraShardsList" -}}
{{- $shards := $.Values.clickhouse.shards | int }}
{{- $list := list -}}
{{- range $shard := until $shards }}
{{- if ne $shard 0 }}
{{- $item := printf "%s-shard%d-%d-external" (include "clickhouse.standby.fullname" $) $shard 0 | trunc 63 | trimSuffix "-" }}
{{- $list = append $list $item }}
{{- end -}}
{{- end -}}
{{- $list | toYaml | nindent 2 }}
{{- end -}}
