{{/*
Resolve the VMCluster name backing the portal "skip slow replicas" query selector.
Order: explicit vmclusters.portalQuery.skipSlowCluster (tpl-evaluated, so it may
reference other values like the autoscalers do) -> else the first extra cluster
defined under vmclusters.clusters. Returns "" when nothing resolves.
*/}}
{{- define "vmclusters.portalQuery.skipSlowCluster" -}}
{{- $pq := (.Values.vmclusters).portalQuery | default dict -}}
{{- $name := tpl ($pq.skipSlowCluster | default "") . | trim -}}
{{- if not $name -}}
{{- $names := keys ((.Values.vmclusters).clusters | default dict) | sortAlpha -}}
{{- if $names -}}{{- $name = index $names 0 -}}{{- end -}}
{{- end -}}
{{- $name -}}
{{- end -}}

{{/*
Build the in-cluster vmselect read URL for a given VMCluster name.
*/}}
{{- define "vmclusters.vmselectUrl" -}}
{{- printf "http://vmselect-%s:8481/select/0/prometheus" . -}}
{{- end -}}
