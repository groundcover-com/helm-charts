{{- define "portal.fullname" -}}
{{- printf "%s-portal" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "portal.base.http.internalUrl" -}}
    {{- printf "http://%s:9999" (include "portal.fullname" .) -}}
{{- end -}}

{{- define "portal.base.http.inCloudUrl" -}}
{{- printf "https://status.%s" .Values.global.ingress.site -}}
{{- end -}}

{{- define "portal.base.http.url" -}}
{{- if .Values.global.ingress.site -}}
    {{- (include "portal.base.http.inCloudUrl" .) -}}
{{- else if not .Values.global.backend.enabled -}}
    {{- fail "backend.enabled is false. No global.ingress.site value provided." -}}
{{- else -}}
    {{- (include "portal.base.http.internalUrl" .) -}}
{{- end -}}
{{- end -}}

{{- define "portal.live.http.url" -}}
{{- printf "%s/health/live" (include "portal.base.http.url" .) -}}
{{- end -}}
