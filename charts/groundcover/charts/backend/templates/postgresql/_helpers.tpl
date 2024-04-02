{{- define "postgresql.primary.init-scripts-configmap" -}}
{{ printf "%s-init-scripts" (include "postgresql.primary.fullname" .) }}
{{- end }}

