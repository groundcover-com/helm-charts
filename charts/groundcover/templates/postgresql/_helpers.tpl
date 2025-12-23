{{- define "postgresql.base.url" -}}
{{- if .Values.global.postgresql.overrideUrl -}}
    {{- .Values.global.postgresql.overrideUrl -}}
{{- else if not .Values.global.postgresql.enabled -}}
    {{- fail "A valid .Values.global.postgresql.overrideUrl is required!" -}}
{{- else -}}
    {{- printf "%s:5432" (include "postgresql.primary.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "postgresql.username" -}}
{{- if .Values.global.postgresql.auth.username -}}
    {{- .Values.global.postgresql.auth.username -}}
{{- else -}}
    {{- "postgres" -}}
{{- end -}}
{{- end -}}

{{- define "postgresql.database" -}}
{{- if .Values.global.postgresql.auth.database -}}
    {{- .Values.global.postgresql.auth.database -}}
{{- else -}}
    {{- "postgres" -}}
{{- end -}}
{{- end -}}