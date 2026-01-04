{{- define "integrations-agent.fullname" -}}
integrations-agent
{{- end -}}

{{- define "integrations-agent.port" -}}
8888
{{- end -}}

{{- define "integrations-agent.url" -}}
{{- printf "http://%s:%s" (include "integrations-agent.fullname" .) (include "integrations-agent.port" .) -}}
{{- end -}}


