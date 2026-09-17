{{/*
bucket-streamer drains the queue bucket's v5/ prefixes into ClickHouse (the
replacement for the S3Queue engine tables). Gated on both the backend and its
own flag so a sensor-only release never renders it.
*/}}
{{- define "bucket-streamer.enabled" -}}
{{- if and .Values.global.backend.enabled .Values.global.bucketStreamer.enabled -}}true{{- end -}}
{{- end -}}

{{- define "bucket-streamer.fullname" -}}
bucket-streamer
{{- end -}}

{{- define "bucket-streamer.configMapName" -}}
{{- printf "%s-config" (include "bucket-streamer.fullname" .) -}}
{{- end -}}

{{- define "bucket-streamer.port" -}}
8080
{{- end -}}

{{- define "bucket-streamer.labels" -}}
{{- include "groundcover.labels" . }}
app: {{ include "bucket-streamer.fullname" . }}
app.kubernetes.io/name: {{ include "bucket-streamer.fullname" . }}
{{- with .Values.bucketStreamer.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "bucket-streamer.selectorLabels" -}}
app: {{ include "bucket-streamer.fullname" . }}
{{- end -}}

{{- define "bucket-streamer.image" -}}
{{- $img := .Values.bucketStreamer.image -}}
{{- printf "%s/%s:%s" (tpl $img.registry .) (tpl $img.repository .) (tpl $img.tag .) -}}
{{- end -}}

{{/*
ServiceAccount the pods run under. A dedicated one is created by default;
set serviceAccount.create=false and serviceAccount.name to reuse an existing
account (e.g. one whose cloud role already grants access to the queue bucket).
*/}}
{{- define "bucket-streamer.serviceAccountName" -}}
{{- $sa := .Values.bucketStreamer.serviceAccount -}}
{{- if $sa.create -}}
{{- default (include "bucket-streamer.fullname" .) $sa.name -}}
{{- else -}}
{{- default "default" $sa.name -}}
{{- end -}}
{{- end -}}

{{/*
Object-store wiring defaults to whatever the sensor's vector sinks write to, so
the streamer reads the same bucket without repeating it in values. Inference
carries vector's own producer guard (templates/vector/_helpers.tpl): a bucket
left in values with objectStorage.allowed false is one nothing writes to, and
following it would point the streamer at an idle store. An explicit
bucketStreamer.objectStore.provider stays an operator override and skips it.
*/}}
{{- define "bucket-streamer.objectStore.provider" -}}
{{- $os := .Values.bucketStreamer.objectStore -}}
{{- $vos := .Values.vector.objectStorage -}}
{{- if $os.provider -}}
{{- if not (has $os.provider (list "s3" "gcs" "azure")) -}}
{{- fail (printf "bucketStreamer.objectStore.provider must be one of s3, gcs, azure (got %q)" $os.provider) -}}
{{- end -}}
{{- $os.provider -}}
{{- else if and $vos.allowed $vos.s3Bucket -}}
s3
{{- else if and $vos.allowed $vos.gcsBucket -}}
gcs
{{- else if and $vos.allowed $vos.azureBlobContainer -}}
azure
{{- else -}}
{{- fail "bucketStreamer: nothing to infer an object store from - set bucketStreamer.objectStore.provider and .bucket, or configure vector.objectStorage with allowed: true and s3Bucket / gcsBucket / azureBlobContainer" -}}
{{- end -}}
{{- end -}}

{{- define "bucket-streamer.objectStore.bucket" -}}
{{- $os := .Values.bucketStreamer.objectStore -}}
{{- $vos := .Values.vector.objectStorage -}}
{{- $provider := include "bucket-streamer.objectStore.provider" . -}}
{{- if $os.bucket -}}
{{- tpl $os.bucket . -}}
{{- else if eq $provider "s3" -}}
{{- required (printf "bucketStreamer: provider %s needs a bucket (set bucketStreamer.objectStore.bucket or vector.objectStorage.s3Bucket)" $provider) $vos.s3Bucket -}}
{{- else if eq $provider "gcs" -}}
{{- required (printf "bucketStreamer: provider %s needs a bucket (set bucketStreamer.objectStore.bucket or vector.objectStorage.gcsBucket)" $provider) $vos.gcsBucket -}}
{{- else if eq $provider "azure" -}}
{{- required (printf "bucketStreamer: provider %s needs a bucket (set bucketStreamer.objectStore.bucket or vector.objectStorage.azureBlobContainer)" $provider) $vos.azureBlobContainer -}}
{{- end -}}
{{- end -}}

{{/*
Both regions unset leaves `default` returning nil, which include stringifies as
Helm's `<no value>` sentinel: truthy to `with`, then stripped from the rendered
output. Callers guard on this, so collapse it to an empty string here.
*/}}
{{- define "bucket-streamer.objectStore.region" -}}
{{- $region := default .Values.vector.objectStorage.region .Values.bucketStreamer.objectStore.region -}}
{{- if $region -}}{{- $region -}}{{- end -}}
{{- end -}}

{{/*
The primary destination is the release's own ClickHouse cluster: shard-0 is the
main shard, shard-1..N are the extra shards (same naming db-manager uses).
The password is a placeholder the init container substitutes at pod start so
it never lands in the ConfigMap.
*/}}
{{- define "bucket-streamer.primaryDestination" -}}
- id: default
  shards:
    - id: shard-0
      endpoint: {{ include "clickhouse.shard0HttpEndpoint" . | trim }}
      database: {{ include "clickhouse.database" . }}
      username: {{ include "clickhouse.username" . }}
      password: "__CH_PASSWORD__"
{{- range $i, $e := until (int .Values.clickhouse.shards) }}
{{- if ne $i 0 }}
    - id: shard-{{ $i }}
      endpoint: http://{{ include "clickhouse.fullname" $ }}-shard{{ $i }}-0-external:{{ $.Values.global.clickhouse.containerPorts.http }}
      database: {{ include "clickhouse.database" $ }}
      username: {{ include "clickhouse.username" $ }}
      password: "__CH_PASSWORD__"
{{- end }}
{{- end }}
{{- end -}}

{{/*
With ClickHouse HA the standby is a second destination, not extra shards on the
primary: extra_shards signals spread batches across a destination's shards, so
listing the standby under the primary would split data between the clusters
instead of mirroring it. Same database, user and password as the primary since
the standby chart block anchors the primary's auth.
*/}}
{{- define "bucket-streamer.standbyDestination" -}}
{{- $standby := index .Values "clickhouse-standby" | default dict }}
{{- $shards := int (default .Values.clickhouse.shards $standby.shards) }}
- id: standby
{{- if .Values.bucketStreamer.standbyDestination.dead }}
  dead: true
{{- end }}
  shards:
    - id: shard-0
      endpoint: {{ include "clickhouse.standby.shard0HttpEndpoint" . | trim }}
      database: {{ include "clickhouse.database" . }}
      username: {{ include "clickhouse.username" . }}
      password: "__CH_PASSWORD__"
{{- range $i, $e := until $shards }}
{{- if ne $i 0 }}
    - id: shard-{{ $i }}
      endpoint: http://{{ include "clickhouse.standby.fullname" $ }}-shard{{ $i }}-0-external:{{ $.Values.global.clickhouse.containerPorts.http }}
      database: {{ include "clickhouse.database" $ }}
      username: {{ include "clickhouse.username" $ }}
      password: "__CH_PASSWORD__"
{{- end }}
{{- end }}
{{- end -}}

{{/*
Rendered config.yaml (minus the ClickHouse password). Signals are keyed by name
in values so a single one can be overridden without restating the rest; they are
emitted as the list the streamer expects, in key order. prefix and input_table go
through tpl so input tables can follow dbManager.objectStorageDestTables.
*/}}
{{- define "bucket-streamer.config" -}}
{{- $bs := .Values.bucketStreamer -}}
postgres:
  dsn: postgres://{{ include "postgresql.username" . }}@{{ include "postgresql.base.url" . }}/{{ $bs.postgres.database }}?sslmode={{ $bs.postgres.sslmode }}
  max_conns: {{ $bs.postgres.maxConns }}

{{- $os := dict "provider" (include "bucket-streamer.objectStore.provider" .) "bucket" (include "bucket-streamer.objectStore.bucket" .) }}
{{- with include "bucket-streamer.objectStore.region" . }}
{{- $_ := set $os "region" . }}
{{- end }}
{{- with $bs.objectStore.endpoint }}
{{- $_ := set $os "endpoint" (tpl . $) }}
{{- end }}
{{/* config.object_store carries tuning only: merge keeps the generated
identity fields, and emitting it as a second top-level mapping would be a
duplicate key the streamer's YAML parser rejects outright. */}}
{{- with $bs.config.object_store }}
{{- $os = merge $os (fromYaml (tpl (toYaml .) $)) }}
{{- end }}
object_store:
{{ toYaml $os | indent 2 }}

destinations:
{{ include "bucket-streamer.primaryDestination" . }}
{{- if and (((.Values.global.clickhouse).ha).enabled) $bs.standbyDestination.enabled }}
{{ include "bucket-streamer.standbyDestination" . }}
{{- end }}
{{- range $bs.extraDestinations }}
- id: {{ required "bucketStreamer.extraDestinations[].id is required" .id }}
{{- if .dead }}
  dead: true
{{- end }}
  shards:
{{- range .shards }}
    - id: {{ required "bucketStreamer.extraDestinations[].shards[].id is required" .id }}
      endpoint: {{ tpl (toString (required "bucketStreamer.extraDestinations[].shards[].endpoint is required" .endpoint)) $ }}
      database: {{ default (include "clickhouse.database" $) .database }}
      username: {{ default (include "clickhouse.username" $) .username }}
      password: {{ default "__CH_PASSWORD__" .password | quote }}
{{- if .draining }}
      draining: true
{{- end }}
{{- if .dead }}
      dead: true
{{- end }}
{{- end }}
{{- end }}

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
{{- $_ := set $s "input_table" (tpl (toString $s.input_table) $) }}
{{- $signals = append $signals $s }}
{{- end }}
{{- end }}
{{- end }}
{{ toYaml $signals | indent 2 }}
{{- end -}}
