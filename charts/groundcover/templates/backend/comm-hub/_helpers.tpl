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
