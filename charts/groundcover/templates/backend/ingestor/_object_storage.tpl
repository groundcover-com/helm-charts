{{- define "ingestor.writesToObjectStorage" -}}
{{- if and .Values.global.ingestor.enabled .Values.global.backend.enabled .Values.global.ingestor.writeToObjectStorage -}}true{{- end -}}
{{- end -}}

{{- define "ingestor.objectStorage.guard" -}}
{{- $os := .Values.vector.objectStorage -}}
{{- $v := .Values.vector -}}
{{- $stay := "global.ingestor.writeToObjectStorage: this backend must stay on Vector" -}}
{{- if eq (toString .Values.vector.enabled) "false" -}}
{{- fail (printf "%s - vector.enabled is false; Vector keeps the other inputs and its vector-s3-secret" $stay) -}}
{{- end -}}
{{- if $os.azureBlobContainer -}}
{{- fail (printf "%s - Azure Blob storage is configured and this writer supports S3 only" $stay) -}}
{{- end -}}
{{- if $os.gcsBucket -}}
{{- fail (printf "%s - vector.objectStorage.gcsBucket is set and this writer supports S3 only" $stay) -}}
{{- end -}}
{{- if not (and $os.allowed $os.s3Bucket) -}}
{{- fail (printf "%s - no bucket: set vector.objectStorage.s3Bucket with allowed: true" $stay) -}}
{{- end -}}
{{- if $os.accessKey -}}
{{- fail (printf "%s - vector.objectStorage.accessKey is set and the ingestor reads credentials only from its pod identity" $stay) -}}
{{- end -}}
{{- if and .Values.global.clickhouse.ha.enabled (not (empty .Values.dbManager.standbyCluster.objectStoragePathPrefix)) (not $v.standbyCluster.disableSinks) -}}
{{- fail (printf "%s - Vector writes the HA standby copies" $stay) -}}
{{- end -}}
{{- if $v.ingestionMetrics.enabled -}}
{{- fail (printf "%s - vector.ingestionMetrics.enabled counts ingestion in Vector" $stay) -}}
{{- end -}}
{{- $sinkGroups := dict "logs" (index $v.customComponents.sinks.s3 "logs") "traces" (index $v.customComponents.sinks.s3 "traces") "custom" (index $v.customComponents.sinks.s3 "custom") -}}
{{- if $os.backups -}}
{{- $backups := index $v.customComponents.sinks "s3Backups" -}}
{{- $_ := set $sinkGroups "backupLogs" $backups.logs -}}
{{- $_ := set $sinkGroups "backupTraces" $backups.traces -}}
{{- end -}}
{{- range $group, $sinks := $sinkGroups -}}
{{- range $name, $sink := $sinks -}}
{{- if or (dig "endpoint" "" $sink) (dig "force_path_style" false $sink) -}}
{{- fail (printf "%s - S3 sink %s sets endpoint or force_path_style and the ingestor writes only to the AWS endpoint" $stay $name) -}}
{{- end -}}
{{- if or (dig "server_side_encryption" "" $sink) (dig "ssekms_key_id" "" $sink) -}}
{{- fail (printf "%s - S3 sink %s sets server-side encryption and the ingestor does not send encryption headers" $stay $name) -}}
{{- end -}}
{{- if eq $group "custom" -}}
{{- $rows := include "ingestor.objectStorage.customRows" (dict "inputs" $sink.inputs) -}}
{{- if contains "," $rows -}}
{{- fail (printf "%s - S3 sink %s takes %s rows and the ingestor writes one row type per stream" $stay $name (replace "," " and " $rows)) -}}
{{- end -}}
{{- end -}}
{{- if hasKey $sink "compression" -}}
{{- fail (printf "%s - S3 sink %s sets compression and the ingestor writes its own object format" $stay $name) -}}
{{- end -}}
{{- if and (hasKey $sink "framing") (ne (toJson $sink.framing) "{\"method\":\"newline_delimited\"}") -}}
{{- fail (printf "%s - S3 sink %s sets framing other than newline_delimited and the ingestor writes newline-delimited rows" $stay $name) -}}
{{- end -}}
{{- $encoding := dig "encoding" (dict) $sink -}}
{{- range $key, $_ := $encoding -}}
{{- if not (has $key (list "codec" "timestamp_format" "except_fields")) -}}
{{- fail (printf "%s - S3 sink %s sets encoding.%s and the ingestor writes its own object format" $stay $name $key) -}}
{{- end -}}
{{- end -}}
{{- if or (ne (toString (dig "codec" "json" $encoding)) "json") (ne (toString (dig "timestamp_format" "rfc3339" $encoding)) "rfc3339") (and (hasKey $encoding "except_fields") (ne (toJson $encoding.except_fields) "[\"log_type\"]")) -}}
{{- fail (printf "%s - S3 sink %s changes encoding.codec, timestamp_format or except_fields from the chart default and the ingestor writes its own object format" $stay $name) -}}
{{- end -}}
{{- if and (tpl (toString (dig "bucket" "" $sink)) $) (ne (tpl (toString (dig "bucket" "" $sink)) $) (toString $os.s3Bucket)) -}}
{{- fail (printf "%s - S3 sink %s overrides the bucket and the ingestor writes every stream to vector.objectStorage.s3Bucket" $stay $name) -}}
{{- end -}}
{{- if and (tpl (toString (dig "region" "" $sink)) $) (ne (tpl (toString (dig "region" "" $sink)) $) (toString (default "" $os.region))) -}}
{{- fail (printf "%s - S3 sink %s overrides the region and the ingestor writes every stream to vector.objectStorage.region" $stay $name) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if (dig "parquetSchemas" "enabled" false $v) -}}
{{- fail (printf "%s - vector.parquetSchemas writes parquet objects" $stay) -}}
{{- end -}}
{{- if or $v.customComponents.sinks.overrideSinks $v.customComponents.transforms.overrideTransforms $v.customComponents.sources.overrideSources $v.customComponents.transforms.extraTransforms $v.customComponents.sinks.extraSinks -}}
{{- fail (printf "%s - vector.customComponents overrides or extends the Vector pipeline" $stay) -}}
{{- end -}}
{{- if $v.eventsPipelines -}}
{{- fail (printf "%s - vector.eventsPipelines turns logs into events in Vector" $stay) -}}
{{- end -}}
{{- if or (ne (len $v.logsPipeline.defaultSteps) 1) (ne (index $v.logsPipeline.defaultSteps 0).name "dropOldLogs") $v.tracesPipeline.defaultSteps -}}
{{- fail (printf "%s - vector.logsPipeline or tracesPipeline defaultSteps are changed" $stay) -}}
{{- end -}}
{{- if or $v.logsPipeline.extraSteps $v.tracesPipeline.extraSteps -}}
{{- fail (printf "%s - vector.logsPipeline or tracesPipeline extraSteps are set" $stay) -}}
{{- end -}}
{{- end -}}

{{- define "ingestor.objectStorage.stream" -}}
{{- $root := .root -}}
{{- $prefix := tpl (toString .sink.key_prefix) $root }}
- rows: {{ .rows }}
  keyPrefix: {{ $prefix | quote }}
  {{- if .backup }}
  backup: true
  storageClass: {{ default "" .sink.storage_class | quote }}
  {{- end }}
  maxBytes: {{ dig "batch" "max_bytes" 0 .sink | int64 }}
  maxEvents: {{ dig "batch" "max_events" 0 .sink | int64 }}
  timeout: {{ printf "%vs" (dig "batch" "timeout_secs" 0 .sink) }}
{{- end -}}

{{- define "ingestor.objectStorage.customRows" -}}
{{- $rows := dict "entities" "entities" "measurements" "measurements" "events" "events" "session_replay" "session_replay" "rum_events" "rum_events" "custom_from_logs_routing.profiling" "profiling" -}}
{{- $found := list -}}
{{- range $input := .inputs -}}
{{- if hasKey $rows $input }}{{ $found = append $found (get $rows $input) }}{{ end -}}
{{- end -}}
{{- $found | uniq | join "," -}}
{{- end -}}

{{- define "ingestor.objectStorage.config" -}}
{{- include "ingestor.objectStorage.guard" . -}}
{{- $sinks := .Values.vector.customComponents.sinks.s3 -}}
{{- $root := . -}}
enabled: true
{{- $os := .Values.vector.objectStorage }}
bucket: {{ $os.s3Bucket | quote }}
region: {{ default "" $os.region | quote }}
streams:
{{- range $sink := $sinks.logs }}
{{ include "ingestor.objectStorage.stream" (dict "root" $root "sink" $sink "rows" "logs") }}
{{- end }}
{{- range $sink := $sinks.traces }}
{{ include "ingestor.objectStorage.stream" (dict "root" $root "sink" $sink "rows" "traces") }}
{{- end }}
{{- range $sink := $sinks.custom }}
{{- $rows := include "ingestor.objectStorage.customRows" (dict "inputs" $sink.inputs) }}
{{- if $rows }}
{{ include "ingestor.objectStorage.stream" (dict "root" $root "sink" $sink "rows" $rows) }}
{{- end }}
{{- end }}
{{- if .Values.vector.objectStorage.backups }}
{{- $backups := index .Values.vector.customComponents.sinks "s3Backups" }}
{{- range $sink := $backups.logs }}
{{ include "ingestor.objectStorage.stream" (dict "root" $root "sink" $sink "rows" "logs" "backup" true) }}
{{- end }}
{{- range $sink := $backups.traces }}
{{ include "ingestor.objectStorage.stream" (dict "root" $root "sink" $sink "rows" "traces" "backup" true) }}
{{- end }}
{{- end }}
{{- end -}}
