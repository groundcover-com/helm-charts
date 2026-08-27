{{- define "clickhouse-proxy.name" -}}
clickhouse-proxy
{{- end -}}

{{- define "clickhouse-proxy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clickhouse-proxy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "clickhouse-proxy.labels" -}}
{{ include "groundcover.labels" . }}
{{ include "clickhouse-proxy.selectorLabels" . }}
{{- end -}}

{{- define "clickhouse-proxy.imageRef" -}}
{{- $img := .image -}}
{{- $registry := $img.registry -}}
{{- if and (not $registry) .ctx.Values.global .ctx.Values.global.origin -}}
{{- $registry = .ctx.Values.global.origin.registry -}}
{{- end -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" $registry $img.repository (toString $img.tag) -}}
{{- else -}}
{{- printf "%s:%s" $img.repository (toString $img.tag) -}}
{{- end -}}
{{- end -}}

{{- define "clickhouse-proxy.image" -}}
{{- include "clickhouse-proxy.imageRef" (dict "image" .Values.clickhouseProxy.image "ctx" .) -}}
{{- end -}}
