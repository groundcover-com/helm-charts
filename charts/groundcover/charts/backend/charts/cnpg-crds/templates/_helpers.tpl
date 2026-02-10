{{- define "cnpg-crds.fullname" -}}
{{- printf "%s-cnpg-crds" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cnpg-crds.job.image" -}}
{{- printf "%s:%s" (tpl .Values.image.repository .) .Values.image.tag -}}
{{- end -}}

{{- define "cnpg-crds.job.annotations" -}}
helm.sh/hook-weight: "0"
helm.sh/hook: "pre-upgrade"
helm.sh/hook-delete-policy: "before-hook-creation"
argocd.argoproj.io/hook: Sync
argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
{{- end -}}

{{- define "cnpg-crds.rbac.annotations" -}}
helm.sh/hook-weight: "-1"
helm.sh/hook: "pre-upgrade"
helm.sh/hook-delete-policy: "before-hook-creation"
{{- end -}}