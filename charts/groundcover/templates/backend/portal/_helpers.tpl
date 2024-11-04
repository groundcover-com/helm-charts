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

{{- define "portal.saas.host" -}}
{{- if .Values.global.airgap -}}
{{- printf "router"  -}}
{{- else -}}
{{- printf "client.groundcover.com"  -}}
{{- end -}}
{{- end -}}

{{- define "portal.saas.port" -}}
{{- if .Values.global.airgap -}}
{{- printf "8080"  -}}
{{- else -}}
{{- printf "443"  -}}
{{- end -}}
{{- end -}}

{{- define "portal.saas.scheme" -}}
{{- if .Values.global.airgap -}}
{{- printf "ws"  -}}
{{- else -}}
{{- printf "wss"  -}}
{{- end -}}
{{- end -}}

{{- define "portal.saas.tls_skip_verify" -}}
{{- if .Values.global.airgap -}}
{{- printf "true"  -}}
{{- else -}}
{{- printf "false"  -}}
{{- end -}}
{{- end -}}
