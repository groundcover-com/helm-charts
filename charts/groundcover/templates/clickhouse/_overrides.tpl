{{/*
Get the Clickhouse password secret name
*/}}
{{- define "clickhouse.secretName" -}}
{{- if typeIs "bool" .Values.global.clickhouse.auth.existingSecret -}}
    {{- include "clickhouse.fullname" . -}}
{{- else -}}
    {{ .Values.global.clickhouse.auth.existingSecret }}
{{- end -}}
{{- end -}}

{{/*
Get the ClickHouse password key inside the secret
*/}}
{{- define "clickhouse.secretKey" -}}
{{ .Values.global.clickhouse.auth.existingSecretKey }}
{{- end -}}
