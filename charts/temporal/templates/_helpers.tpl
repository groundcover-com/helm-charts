{{/*
Temporal helpers
*/}}

{{/*
Node selector for temporal pods
*/}}
{{- define "temporal.nodeSelector" -}}
{{- if .Values.global.temporal.nodeSelector -}}
{{- toYaml .Values.global.temporal.nodeSelector | nindent 0 -}}
{{- else if .Values.temporal.nodeSelector -}}
{{- toYaml .Values.temporal.nodeSelector | nindent 0 -}}
{{- end -}}
{{- end -}}

{{/*
Tolerations for temporal pods
*/}}
{{- define "temporal.tolerations" -}}
{{- if .Values.global.temporal.tolerations -}}
{{- toYaml .Values.global.temporal.tolerations | nindent 0 -}}
{{- else if .Values.temporal.tolerations -}}
{{- toYaml .Values.temporal.tolerations | nindent 0 -}}
{{- end -}}
{{- end -}}

{{/*
Node affinity for temporal pods
*/}}
{{- define "temporal.nodeAffinity" -}}
{{- if .Values.global.temporal.nodeAffinity -}}
    {{- toYaml .Values.global.temporal.nodeAffinity | nindent 0 -}}
{{- else if .Values.temporal.nodeAffinity -}}
    {{- toYaml .Values.temporal.nodeAffinity | nindent 0 -}}
{{- end -}}
{{- end -}}

{{- define "temporal.usesBundledPostgres" -}}
{{- and (dig "postgresql" "enabled" false .Values.global) (ne (dig "postgres" "host" "NONE" .Values.temporalConfig) "NONE") -}}
{{- end -}}

{{- define "temporal.schemaSetup.jobName" -}}
{{- $bundled := eq (include "temporal.usesBundledPostgres" .) "true" -}}
{{- if and $bundled .Release.IsInstall -}}
{{ .Release.Name }}-temporal-schema-setup-bootstrap
{{- else -}}
{{ .Release.Name }}-temporal-schema-setup
{{- end -}}
{{- end -}}

{{- define "temporal.schemaSetup.annotations" -}}
{{- $bundled := eq (include "temporal.usesBundledPostgres" .) "true" -}}
{{- if and $bundled .Release.IsInstall -}}
{{- else if $bundled -}}
helm.sh/hook: pre-upgrade
helm.sh/hook-weight: "-5"
helm.sh/hook-delete-policy: before-hook-creation
{{- else -}}
{{- with .Values.temporalConfig.schemaSetup.annotations -}}
{{- toYaml . -}}
{{- end -}}
{{- end -}}
{{- end -}}
