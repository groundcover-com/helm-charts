{{- define "keep.postgres.password" -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace "keep-postgres" | default dict) -}}
{{- if $secret -}}
    {{- index $secret "data" "password" | b64dec -}}
{{- else -}}
    {{- randAlphaNum 16 -}}
{{- end -}}
{{- end -}}

{{- define "keep.webhook.apikey" -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace "keep-credentials" | default dict) -}}
{{- if $secret -}}
    {{- index $secret "data" "webhook-key" | b64dec -}}
{{- else -}}
    {{- randAlphaNum 16 -}}
{{- end -}}
{{- end -}}

{{- define "keep.admin.apikey" -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace "keep-credentials" | default dict) -}}
{{- if $secret -}}
    {{- index $secret "data" "admin-api-key" | b64dec -}}
{{- else -}}
    {{- randAlphaNum 16 -}}
{{- end -}}
{{- end -}}

{{- define "keep.backend.fullname" -}}
{{- printf "%s-keep-backend" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "keep.admin.password" -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace "keep-credentials" | default dict) -}}
{{- if $secret -}}
    {{- index $secret "data" "password" | b64dec -}}
{{- else -}}
    {{- randAlphaNum 16 -}}
{{- end -}}
{{- end -}}

{{- define "keep.base.url" -}}
{{ printf "http://%s:%v" (include "keep.backend.fullname" .)  .Values.global.keep.backend.service.port -}}
{{- end -}}

{{- define "keep.event.alert.url" -}}
{{ printf "%s/alerts/event/grafana" (include "keep.base.url" .) }}
{{- end -}}

