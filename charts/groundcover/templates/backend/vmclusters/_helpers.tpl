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

{{/*
Name of the Secret holding the dual-shipping creation timestamp (portal-consumed).
*/}}
{{- define "vmclusters.dualShipping.secretName" -}}
{{- printf "%s-vmclusters-dualshipping" .Release.Name -}}
{{- end -}}

{{/*
Dual-shipping creation timestamp. Generated once (now, RFC3339 UTC) on first install
and preserved verbatim across upgrades by reading it back from the existing Secret via
lookup, so it always reflects the moment the Secret was first created.
*/}}
{{- define "vmclusters.dualShipping.createdAt" -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "vmclusters.dualShipping.secretName" .) | default dict) -}}
{{- $existing := "" -}}
{{- if and $secret (hasKey (default dict (index $secret "data")) "created-at") -}}
{{- $existing = index $secret "data" "created-at" | b64dec -}}
{{- end -}}
{{- if $existing -}}
{{- $existing -}}
{{- else -}}
{{- dateInZone "2006-01-02T15:04:05Z07:00" now "UTC" -}}
{{- end -}}
{{- end -}}
