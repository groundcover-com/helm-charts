{{/* A second bucket-streamer instance: one process runs one sink kind, so the http sink needs its own Deployment and Postgres database. */}}
{{- define "queue-bucket-streamer.enabled" -}}
{{- include "queue.enabled" . -}}
{{- end -}}

{{/* Labels and selectors keep the short name; only resource names carry the release. */}}
{{- define "queue-bucket-streamer.name" -}}
queue-bucket-streamer
{{- end -}}

{{- define "queue-bucket-streamer.fullname" -}}
{{- printf "%s-queue-bucket-streamer" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "queue-bucket-streamer.configMapName" -}}
{{- printf "%s-config" (include "queue-bucket-streamer.fullname" .) -}}
{{- end -}}

{{- define "queue-bucket-streamer.port" -}}
8080
{{- end -}}

{{- define "queue-bucket-streamer.labels" -}}
{{- include "groundcover.labels" . }}
app: {{ include "queue-bucket-streamer.name" . }}
app.kubernetes.io/name: {{ include "queue-bucket-streamer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- with .Values.queueBucketStreamer.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "queue-bucket-streamer.selectorLabels" -}}
app: {{ include "queue-bucket-streamer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

{{- define "queue-bucket-streamer.image" -}}
{{- $img := .Values.queueBucketStreamer.image -}}
{{- printf "%s/%s:%s" (tpl $img.registry .) (tpl $img.repository .) (tpl (toString $img.tag) .) -}}
{{- end -}}

{{- define "queue-bucket-streamer.serviceAccountName" -}}
{{- $sa := .Values.queueBucketStreamer.serviceAccount -}}
{{- if $sa.create -}}
{{- default (include "queue-bucket-streamer.fullname" .) $sa.name -}}
{{- else -}}
{{- default "default" $sa.name -}}
{{- end -}}
{{- end -}}

{{- define "queue-bucket-streamer.objectStore.bucket" -}}
{{- with .Values.queueBucketStreamer.objectStore.bucket -}}
{{- tpl . $ -}}
{{- else -}}
{{- include "queue.objectStore.bucket" . -}}
{{- end -}}
{{- end -}}

{{- define "queue-bucket-streamer.objectStore.region" -}}
{{- $region := default (include "queue.objectStore.region" .) .Values.queueBucketStreamer.objectStore.region -}}
{{- if $region -}}{{- $region -}}{{- end -}}
{{- end -}}

{{- define "queue-bucket-streamer.objectStore.endpoint" -}}
{{- $endpoint := default .Values.queue.objectStore.endpoint .Values.queueBucketStreamer.objectStore.endpoint -}}
{{- if $endpoint -}}{{- tpl $endpoint . -}}{{- end -}}
{{- end -}}

{{/* Follows the queue's store.prefix so the two cannot drift; an empty prefix is the bucket root. */}}
{{- define "queue-bucket-streamer.signalPrefix" -}}
{{- $store := dig "store" (dict) (.root.Values.queue.config | default dict) -}}
{{- $prefix := trimAll "/" (toString (dig .key .default $store)) -}}
{{- if $prefix -}}{{ $prefix }}/v1/{{- else -}}v1/{{- end -}}
{{- end -}}

{{- define "queue-bucket-streamer.ingestorUrl" -}}
{{- with .Values.queueBucketStreamer.ingestor.url -}}
{{- tpl . $ | trimSuffix "/" -}}
{{- else -}}
{{- if not .Values.global.ingestor.enabled -}}
{{- fail "queueBucketStreamer: global.ingestor.enabled is false and queueBucketStreamer.ingestor.url is empty, so there is nowhere to deliver the queue's objects" -}}
{{- end -}}
{{- printf "http://%s:%s" (include "ingestor.fullname" .) (include "ingestor.otlphttp.port" .) -}}
{{- end -}}
{{- end -}}

{{/* An OTLP receiver serves one path per signal, so each signal gets its own destination. */}}
{{- define "queue-bucket-streamer.destinations" -}}
{{- $base := include "queue-bucket-streamer.ingestorUrl" . -}}
- id: ingestor-logs
  shards:
    - id: primary
      endpoint: {{ $base }}/v1/logs
- id: ingestor-traces
  shards:
    - id: primary
      endpoint: {{ $base }}/v1/traces
{{- end -}}

{{- define "queue-bucket-streamer.config" -}}
{{- $bs := .Values.queueBucketStreamer -}}
postgres:
  dsn: postgres://{{ include "postgresql.username" . }}@{{ include "postgresql.base.url" . }}/{{ $bs.postgres.database }}?sslmode={{ $bs.postgres.sslmode }}
  max_conns: {{ $bs.postgres.maxConns }}

{{- $os := dict "provider" "s3" "bucket" (include "queue-bucket-streamer.objectStore.bucket" .) }}
{{- with include "queue-bucket-streamer.objectStore.region" . }}
{{- $_ := set $os "region" . }}
{{- end }}
{{- with include "queue-bucket-streamer.objectStore.endpoint" . }}
{{- $_ := set $os "endpoint" . }}
{{- end }}
{{- if eq (toString .Values.queue.objectStore.pathStyle) "true" }}
{{- $_ := set $os "force_path_style" true }}
{{- end }}
{{/* object_store tuning merges into the generated block: a second top-level key is a duplicate the parser rejects. */}}
{{- with $bs.config.object_store }}
{{- $os = merge $os (fromYaml (tpl (toYaml .) $)) }}
{{- end }}
object_store:
{{ toYaml $os | indent 2 }}

sink:
  type: http
{{- with $bs.sink.http }}
  http:
{{ tpl (toYaml .) $ | indent 4 }}
{{- end }}

destinations:
{{ include "queue-bucket-streamer.destinations" . }}

{{- range $section, $body := $bs.config }}
{{- if and $body (ne $section "object_store") }}

{{ $section }}:
{{ tpl (toYaml $body) $ | indent 2 }}
{{- end }}
{{- end }}

signals:
{{- $signals := list }}
{{- range $name, $signal := $bs.signals }}
{{- if $signal }}
{{- $enabled := dig "enabled" true $signal }}
{{- if kindIs "string" $enabled }}
{{- $enabled = not (has (lower $enabled) (list "" "false" "0")) }}
{{- end }}
{{- if $enabled }}
{{- $s := mergeOverwrite (deepCopy ($bs.signalDefaults | default dict)) (deepCopy $signal) }}
{{- $_ := unset $s "enabled" }}
{{- $_ := set $s "name" (default $name $s.name) }}
{{- $_ := set $s "prefix" (tpl (toString $s.prefix) $) }}
{{- $signals = append $signals $s }}
{{- end }}
{{- end }}
{{- end }}
{{ toYaml $signals | indent 2 }}
{{- end -}}
