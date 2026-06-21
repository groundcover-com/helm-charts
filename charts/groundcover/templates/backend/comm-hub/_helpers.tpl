{{- define "comm-hub.fullname" -}}
{{- printf "%s-comm-hub" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Comm Hub config map name
*/}}
{{- define "comm-hub.configMapName" -}}
{{- printf "%s-comm-hub-config" .Release.Name -}}
{{- end -}}

{{/*
Comm Hub Temporal availability for OAuth refresh.
*/}}
{{- define "comm-hub.temporalEnabled" -}}
{{- if or (and .Values.global.backend.enabled .Values.global.temporal.enabled) .Values.commHub.temporal.host -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{/*
Comm Hub OAuth refresh disabled flag as rendered into config.yaml.
*/}}
{{- define "comm-hub.oauthRefreshDisabled" -}}
{{- if or (.Values.commHub | dig "oauthRefresh" "disabled" false) (ne (include "comm-hub.temporalEnabled" .) "true") -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{/*
Release-scoped OAuth refresh task queue.
*/}}
{{- define "comm-hub.oauthRefreshTaskQueue" -}}
{{- $override := .Values.commHub | dig "oauthRefresh" "taskQueue" "" -}}
{{- $override | default (printf "%s-%s-comm-hub-oauth-refresh" .Release.Namespace .Release.Name | trunc 200 | trimSuffix "-") -}}
{{- end -}}

{{/*
Release-scoped OAuth refresh singleton workflow ID.
*/}}
{{- define "comm-hub.oauthRefreshWorkflowID" -}}
{{- $override := .Values.commHub | dig "oauthRefresh" "workflowId" "" -}}
{{- $override | default (printf "%s-%s-comm-hub-oauth-refresh-workflow" .Release.Namespace .Release.Name | trunc 200 | trimSuffix "-") -}}
{{- end -}}

{{/*
Comm Hub encryption secret name
*/}}
{{- define "comm-hub.encryptionSecretName" -}}
{{- if .Values.commHub.encryption.existingSecret -}}
{{- .Values.commHub.encryption.existingSecret -}}
{{- else -}}
{{- printf "%s-comm-hub-encryption" .Release.Name -}}
{{- end -}}
{{- end -}}

{{/*
Comm Hub encryption secret key name — centralised default
*/}}
{{- define "comm-hub.encryptionSecretKeyName" -}}
{{- .Values.commHub.encryption.secretKey | default "encryption-key" -}}
{{- end -}}

{{/*
Comm Hub encryption key - lookup existing or generate new
*/}}
{{- define "comm-hub.encryptionKey" -}}
{{- $keyName := include "comm-hub.encryptionSecretKeyName" . -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "comm-hub.encryptionSecretName" .) | default dict) -}}
{{- $existing := "" -}}
{{- if and $secret (hasKey (default dict (index $secret "data")) $keyName) -}}
    {{- $existing = index $secret "data" $keyName | b64dec -}}
{{- end -}}
{{- if $existing -}}
    {{- $existing -}}
{{- else -}}
    {{- randBytes 32 -}}
{{- end -}}
{{- end -}}
