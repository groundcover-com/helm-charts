{{/*
Keeper fullname
*/}}
{{- define "keeper.fullname" -}}
{{- printf "%s-clickhouse-keeper" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Keeper headless service name
*/}}
{{- define "keeper.headless.fullname" -}}
{{- printf "%s-headless" (include "keeper.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Keeper common selector labels
*/}}
{{- define "keeper.selectorLabels" -}}
app: {{ include "keeper.fullname" . }}
{{- end -}}

{{/*
Keeper labels
*/}}
{{- define "keeper.labels" -}}
{{ include "keeper.selectorLabels" . }}
{{- include "groundcover.labels" . | nindent 0 }}
app.kubernetes.io/name: clickhouse-keeper
{{- end -}}

{{/*
Generate raft configuration XML for keeper nodes
*/}}
{{- define "keeper.raftConfiguration" -}}
<raft_configuration>
{{- $fullname := include "keeper.fullname" . -}}
{{- $headless := include "keeper.headless.fullname" . -}}
{{- $namespace := .Release.Namespace -}}
{{- $raftPort := .Values.keeper.ports.raft | int -}}
{{- range $i := until (.Values.keeper.replicas | int) }}
    <server>
        <id>{{ $i }}</id>
        <hostname>{{ $fullname }}-{{ $i }}.{{ $headless }}.{{ $namespace }}.svc.cluster.local</hostname>
        <port>{{ $raftPort }}</port>
    </server>
{{- end }}
</raft_configuration>
{{- end -}}
