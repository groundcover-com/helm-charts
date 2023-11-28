{{- define "volume-expansion.fullname" -}}
{{- printf "%s-volume-expansion" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "volume-expansion.pvc.patch" -}}
op: replace
value: {{ . }}
path: /spec/resources/requests/storage
{{- end -}}

{{- define "volume-expansion.sts.patch" -}}
op: replace
value: {{ . }}
path: /spec/volumeClaimTemplates/0/spec/resources/requests/storage
{{- end -}}

{{- define "volume-expansion.job.image" -}}
{{- printf "%s:%s" (tpl (index .Values "volume-expansion" "image" "repository") .) (index .Values "volume-expansion" "image" "tag") -}}
{{- end -}}

{{- define "volume-expansion.job.annotations" -}}
helm.sh/hook-weight: "0"
helm.sh/hook: "pre-upgrade"
helm.sh/hook-delete-policy: "before-hook-creation,hook-succeeded"
{{- end -}}

{{- define "volume-expansion.rbac.annotations" -}}
helm.sh/hook-weight: "-1"
helm.sh/hook: "pre-upgrade"
helm.sh/hook-delete-policy: "before-hook-creation,hook-succeeded"
{{- end -}}
