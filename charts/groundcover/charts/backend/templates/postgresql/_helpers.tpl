{{- define "postgresql.primary.init-scripts-configmap" -}}
{{ printf "%s-init-scripts" (include "postgresql.primary.fullname" .) }}
{{- end }}

{{- define "postgresql.job.create-dbs.annotations" -}}
helm.sh/hook-weight: "0"
helm.sh/hook: "post-upgrade"
helm.sh/hook-delete-policy: "before-hook-creation,hook-succeeded"
{{- end -}}