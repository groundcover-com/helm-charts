{{- define "clickhouse.fullname" -}}
{{- printf "%s-clickhouse" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "clickhouse.database" -}}
{{-  print "groundcover" -}}
{{- end -}}

{{- define "clickhouse.username" -}}
{{-  print "default" -}}
{{- end -}}

{{- define "clickhouse.password" -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "clickhouse.secretName" .) | default dict) -}}
{{- if .Values.global.clickhouse.auth.password -}}
    {{- .Values.global.clickhouse.auth.password -}}
{{- else if $secret -}}
    {{- index $secret "data" (include "clickhouse.secretKey" .) | b64dec -}}
{{- else -}}
    {{- randAlphaNum 16 -}}
{{- end -}}
{{- end -}}

{{- define "clickhouse.nativeEndpoint" -}}
{{-  printf "clickhouse://%s:%d" (include "clickhouse.fullname" .) (.Values.global.clickhouse.containerPorts.tcp | int ) -}}
{{- end -}}

{{- define "clickhouse.httpEndpoint" -}}
{{-  printf "http://%s:%d" (include "clickhouse.fullname" .) (.Values.global.clickhouse.containerPorts.http | int ) -}}
{{- end -}}
