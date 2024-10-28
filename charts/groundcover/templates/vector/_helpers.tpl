{{- define "vector.s3.secretName" -}}
{{ print "vector-s3-secret" }}
{{- end -}}

{{- define "vector.s3.secretKey" -}}
{{- print "S3_ACCESS_KEY_SECRET" -}}
{{- end -}}

{{- define "vector.s3.accessKey" -}}
{{- print "S3_ACCESS_KEY" -}}
{{- end -}}

{{- define "vector.cluster.http.health.port" -}}
{{-  printf "8686"  -}}
{{- end -}}

{{- define "vector.cluster.http.health.endpoint" -}}
{{-  printf "%s://%s:%d" (include "vector.otlp.scheme" .) (include "vector.fullname" .) (include "vector.cluster.http.health.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.http.health.url" -}}
{{-  printf "%s/health" (include "vector.cluster.http.health.endpoint" .) -}}
{{- end -}}

{{- define "vector.incloud.http.health.url" -}}
{{-  printf "%s/ingest/v2/health" (include "incloud.ingestion.http.url" .) -}}
{{- end -}}

{{- define "vector.otlp.scheme" -}}
{{- ternary "https" "http" .Values.global.otlp.tls.enabled -}}
{{- end -}}

{{- define "vector.otlp.http.tls.enabled" -}}
{{- eq (get (urlParse (include "vector.logs.otlp.http.url" .)) "scheme") "https" -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.logs.port" -}}
{{-  printf "4317"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.logs.endpoint" -}}
{{-  printf "%s:%d" (include "vector.fullname" .) (include "vector.cluster.otlp.grpc.logs.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.logs.port" -}}
{{-  printf "4318"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.logs.endpoint" -}}
{{-  printf "%s://%s:%d" (include "vector.otlp.scheme" .) (include "vector.fullname" .) (include "vector.cluster.otlp.http.logs.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.logs.url" -}}
{{-  printf "%s/v1/logs" (include "vector.cluster.otlp.http.logs.endpoint" .) -}}
{{- end -}}

{{- define "vector.incloud.otlp.http.logs.url" -}}
{{-  printf "%s/ingest/v2/otlp/logs" (include "incloud.ingestion.http.url" .) -}}
{{- end -}}

{{- define "vector.cluster.json.logs.port" -}}
{{- printf "4319" -}}
{{- end -}}

{{- define "vector.incloud.json.logs.url" -}}
{{- printf "%s/logs" (include "incloud.ingestion.json.url" .) -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.traces.port" -}}
{{-  printf "4327"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.traces.endpoint" -}}
{{-  printf "%s:%d" (include "vector.fullname" .) (include "vector.cluster.otlp.grpc.traces.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.traces.port" -}}
{{-  printf "4328"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.traces.endpoint" -}}
{{-  printf "%s://%s:%d" (include "vector.otlp.scheme" .) (include "vector.fullname" .) (include "vector.cluster.otlp.http.traces.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.traces-as-logs.url" -}}
{{-  printf "%s/v1/logs" (include "vector.cluster.otlp.http.traces.endpoint" .) -}}
{{- end -}}

{{- define "vector.incloud.otlp.http.traces-as-logs.url" -}}
{{-  printf "%s/ingest/v2/otlp/traces-as-logs" (include "incloud.ingestion.http.url" .) -}}
{{- end -}}

{{- define "vector.cluster.json.traces-as-logs.port" -}}
{{- printf "4329" -}}
{{- end -}}

{{- define "vector.incloud.json.traces-as-logs.url" -}}
{{- printf "%s/traces-as-logs" (include "incloud.ingestion.json.url" .) -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.custom.port" -}}
{{-  printf "4337"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.custom.endpoint" -}}
{{-  printf "%s:%d" (include "vector.fullname" .) (include "vector.cluster.otlp.grpc.custom.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.custom.port" -}}
{{-  printf "4338"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.custom.endpoint" -}}
{{-  printf "%s://%s:%d" (include "vector.otlp.scheme" .) (include "vector.fullname" .) (include "vector.cluster.otlp.http.custom.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.custom.url" -}}
{{-  printf "%s/v1/logs" (include "vector.cluster.otlp.http.custom.endpoint" .) -}}
{{- end -}}

{{- define "vector.incloud.otlp.http.custom.url" -}}
{{-  printf "%s/ingest/v2/otlp/custom" (include "incloud.ingestion.http.url" .) -}}
{{- end -}}

{{- define "vector.cluster.json.events.port" -}}
{{- printf "4359" -}}
{{- end -}}

{{- define "vector.incloud.json.events.url" -}}
{{- printf "%s/events" (include "incloud.ingestion.json.url" .) -}}
{{- end -}}

{{- define "vector.cluster.json.entities.port" -}}
{{- printf "4369" -}}
{{- end -}}

{{- define "vector.incloud.json.entities.url" -}}
{{- printf "%s/entities" (include "incloud.ingestion.json.url" .) -}}
{{- end -}}

{{- define "vector.cluster.json.measurements.port" -}}
{{- printf "4379" -}}
{{- end -}}

{{- define "vector.incloud.json.measurements.url" -}}
{{- printf "%s/measurements" (include "incloud.ingestion.json.url" .) -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.monitors.port" -}}
{{-  printf "4347"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.grpc.monitors.endpoint" -}}
{{-  printf "%s:%d" (include "vector.fullname" .) (include "vector.cluster.otlp.grpc.monitors.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.prometheus_remote_write.vm_metrics.port" -}}
{{-  printf "4599"  -}}
{{- end -}}

{{- define "vector.cluster.prometheus_remote_write.vm_metrics.endpoint" -}}
{{-  printf "http://%s:%d" (include "vector.fullname" .) (include "vector.cluster.prometheus_remote_write.vm_metrics.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.monitors.port" -}}
{{-  printf "4348"  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.monitors.endpoint" -}}
{{-  printf "%s://%s:%d" (include "vector.otlp.scheme" .) (include "vector.fullname" .) (include "vector.cluster.otlp.http.monitors.port" . | int )  -}}
{{- end -}}

{{- define "vector.cluster.otlp.http.monitors.url" -}}
{{-  printf "%s/v1/logs" (include "vector.cluster.otlp.http.monitors.endpoint" .) -}}
{{- end -}}

{{- define "vector.tracesAsLogs.otlp.http.url" -}}
{{- if .Values.global.vector.tracesAsLogs.otlp.overrideHttpURL -}}
    {{- print .Values.global.vector.tracesAsLogs.otlp.overrideHttpURL -}}
{{- else -}}
    {{- include "vector.cluster.otlp.http.traces-as-logs.url" . -}}
{{- end -}}
{{- end -}}

{{- define "vector.logs.otlp.http.url" -}}
{{- if .Values.global.vector.logs.otlp.overrideHttpURL -}}
    {{- print .Values.global.vector.logs.otlp.overrideHttpURL -}}
{{- else -}}
    {{- include "vector.cluster.otlp.http.logs.url" . -}}
{{- end -}}
{{- end -}}

{{- define "vector.custom.otlp.http.url" -}}
{{- if .Values.global.vector.custom.otlp.overrideHttpURL -}}
    {{- print .Values.global.vector.custom.otlp.overrideHttpURL -}}
{{- else -}}
    {{- include "vector.cluster.otlp.http.custom.url" . -}}
{{- end -}}
{{- end -}}

{{- define "vector.health.http.url" -}}
{{- if .Values.global.vector.health.overrideHttpURL -}}
    {{- print .Values.global.vector.health.overrideHttpURL -}}
{{- else if .Values.global.ingress.site -}}
    {{- include "vector.incloud.http.health.url" . -}}
{{- else if not .Values.global.backend.enabled -}}
    {{- fail "A valid global.ingress.site or global.vector.health.overrideHttpURL is required!" -}}
{{- else -}}
    {{- include "vector.cluster.http.health.url" . -}}
{{- end -}}
{{- end -}}

{{- define "vector.config.sinks.telemetry" -}}
telemtry_prometheus_sink:
        type: prometheus_exporter
        inputs:
          - enriched_telemetry_metrics
{{- end -}}

{{- define "vector.config.transforms.telemetry" -}}
enriched_telemetry_metrics:
  type: remap
  inputs:
      - telemetry_metrics
  source: |-
{{ if .Values.global.backend.enabled }}
    .tags.vector_type = "backend"
{{ else }}
    .tags.vector_type = "front"
{{ end }}
{{- end -}}

{{- define "vector.config.sources.telemetry" -}}
telemetry_metrics:
  type: internal_metrics
{{- end -}}

{{- define "vector.config.customConfig" -}}

{{ if .Values.vector.customGlobalConfig }}
{{- tpl (toYaml .Values.vector.customGlobalConfig) $ }}
{{ end }}

sources:
{{- include "vector.config.sources.telemetry" . | nindent 2 }}
{{ if .Values.vector.customComponents.sources.overrideSources }}
{{- tpl (toYaml .Values.vector.customComponents.sources.overrideSources) $ | nindent 2 -}}
{{ else }}
{{ if .Values.vector.customComponents.sources.extraSources }}
{{- tpl (toYaml .Values.vector.customComponents.sources.extraSources) $ | nindent 2 }}
{{ end }}
{{- tpl (toYaml .Values.vector.customComponents.sources.otel) $ | nindent 2 }}
{{- tpl (toYaml .Values.vector.customComponents.sources.json) $ | nindent 2 }}
{{- tpl (toYaml .Values.vector.customComponents.sources.metrics) $ | nindent 2 }}
{{- tpl (toYaml .Values.vector.customComponents.sources.empty) $ | nindent 2 }}
{{ end }}

transforms:
{{- include "vector.config.transforms.telemetry" . | nindent 2 }}
{{ if .Values.vector.customComponents.transforms.overrideTransforms }}
{{- tpl (toYaml .Values.vector.customComponents.transforms.overrideTransforms) $ | nindent 2 -}}
{{ else }}
{{ if .Values.vector.customComponents.transforms.extraTransforms }}
{{- tpl (toYaml .Values.vector.customComponents.transforms.extraTransforms) $ | nindent 2 }}
{{ end }}
{{- tpl (toYaml .Values.vector.customComponents.transforms.default) $ | nindent 2 }}
{{- tpl (include "createPipelineStages" (dict "pipeline" .Values.vector.logsPipeline)) $ }}
{{- tpl (include "createPipelineStages" (dict "pipeline" .Values.vector.tracesPipeline)) $ }}
{{- tpl (include "createEventsPipelines" (dict "pipelines" .Values.vector.eventsPipelines)) $ -}}
{{- tpl (include "logsToEventsTransform" (dict "pipelines" .Values.vector.eventsPipelines "transform" .Values.vector.customComponents.transforms.logs_to_events)) $ }}
{{ end }}

sinks:
{{ if .Values.vector.customComponents.sinks.overrideSinks }}
{{- tpl (toYaml .Values.vector.customComponents.sinks.overrideSinks) $ | nindent 2 -}}
{{ else }}
{{- include "vector.config.sinks.telemetry" . | nindent 2 }}
{{ if .Values.vector.customComponents.sinks.extraSinks }}
{{- tpl (toYaml .Values.vector.customComponents.sinks.extraSinks) $ | nindent 2 }}
{{ end }}
{{- tpl (toYaml .Values.vector.customComponents.sinks.metrics) $ | nindent 2 }}
{{  if and (not (empty .Values.vector.objectStorage.s3Bucket)) .Values.vector.objectStorage.allowed }}
{{- tpl (include "createSinksOutput" (dict "pipeline" .Values.vector.logsPipeline "sinks" .Values.vector.customComponents.sinks.s3.logs)) $ -}}
{{- tpl (include "createSinksOutput" (dict "pipeline" .Values.vector.tracesPipeline "sinks" .Values.vector.customComponents.sinks.s3.traces)) $ -}}
{{- tpl (toYaml .Values.vector.customComponents.sinks.s3.custom) $ | nindent 2 }}
{{  if .Values.global.backend.enabled }}
{{- tpl (toYaml (dict "clickhouse_monitors" .Values.vector.customComponents.sinks.local.custom.clickhouse_monitors)) $ | nindent 2 }}
{{- tpl (toYaml (dict "clickhouse_metrics_metadata" .Values.vector.customComponents.sinks.local.custom.clickhouse_metrics_metadata)) $ | nindent 2 }}
{{ end }}
{{ else if .Values.global.backend.enabled }}
{{- tpl (include "createSinksOutput" (dict "pipeline" .Values.vector.logsPipeline "sinks" .Values.vector.customComponents.sinks.local.logs)) $ -}}
{{- tpl (include "createSinksOutput" (dict "pipeline" .Values.vector.tracesPipeline "sinks" .Values.vector.customComponents.sinks.local.traces)) $ -}}
{{- tpl (toYaml .Values.vector.customComponents.sinks.local.custom) $ | nindent 2 }}
{{ else }}
{{- tpl (include "createSinksOutput" (dict "pipeline" .Values.vector.logsPipeline "sinks" .Values.vector.customComponents.sinks.remote.logs)) $ -}}
{{- tpl (include "createSinksOutput" (dict "pipeline" .Values.vector.tracesPipeline "sinks" .Values.vector.customComponents.sinks.remote.traces)) $ -}}
{{- tpl (toYaml .Values.vector.customComponents.sinks.remote.custom) $ | nindent 2 }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "createPipelineStages" -}}
{{ $allSteps := concat .pipeline.defaultSteps .pipeline.extraSteps }}
{{ if not (empty $allSteps) }}
{{- $previousStep := "" }}
{{- $index := 0 }}
{{- range $step := $allSteps }}
  {{ $step.name }}:
    inputs:
{{ if eq $index 0 }}
{{- toYaml $.pipeline.inputs | nindent 4 }}
{{ else }}
    -   {{ $previousStep }}
{{ end }}
{{ $step.transform | toYaml | nindent 4 }}
{{- $previousStep = $step.name }}
{{- $index = add $index 1 }}
{{- end }}
{{ end }}
{{ end }}

{{- define "createEventsPipelines" -}}
{{ range $k, $v := .pipelines }}
{{ $finalStep :=  (list (dict "name" (include "eventsPipelineFinalStepName" $k) "transform" (dict "type" "remap" "source" (printf ".event_type = \"%s\"" $k)) )) }}
{{- include "createPipelineStages" (dict "pipeline" (merge (dict "extraSteps" (concat $v.extraSteps $finalStep)) $v)) }}
{{ end }}
{{ end }}

{{- define "pipelineOutputFromSteps" -}}
{{ $allSteps := concat .pipeline.defaultSteps .pipeline.extraSteps }}
{{ if not (empty $allSteps) }}
{{- $lastStep := index $allSteps (sub (len $allSteps) 1) }}
{{ printf "- %s" $lastStep.name }}
{{ else }}
{{- toYaml $.pipeline.inputs | nindent 4 }}
{{ end }}
{{- end -}}

{{define "createSinksOutput"}}
{{- range $k, $v := .sinks }}
  {{ $k }}:
    inputs:
    {{- include "pipelineOutputFromSteps" (dict "pipeline" $.pipeline ) | nindent 4 }}
    {{ toYaml . | nindent 4 }}
{{ end }}
{{end}}

{{ define "logsToEventsTransform" }} 
  logs_to_events_transform:
    inputs:
    - emptySource
    {{- range $k, $v := .pipelines }}
    - {{ include "eventsPipelineFinalStepName" $k }}
    {{- end }}
    {{ toYaml $.transform | nindent 4 }}
{{ end }}

{{- define "eventsPipelineFinalStepName" -}}
{{ printf "_final_%s" . -}}
{{ end }}