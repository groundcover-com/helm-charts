{{/*
Get the Clickhouse password secret name
*/}}
{{- define "clickhouse.secretName" -}}
{{- default (include "clickhouse.fullname" .) .Values.global.clickhouse.auth.existingSecret -}}
{{- end -}}

{{/*
Get the ClickHouse password key inside the secret
*/}}
{{- define "clickhouse.secretKey" -}}
{{ .Values.global.clickhouse.auth.existingSecretKey }}
{{- end -}}
