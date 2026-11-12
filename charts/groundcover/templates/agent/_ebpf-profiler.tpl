{{- define "groundcover.ebpfProfiler.enabled" -}}
{{- $root := .root -}}
{{- $sensorValues := .sensorValues -}}
{{- $enabled := dig "receivers" "profiles" "ebpfProfiler" "enabled" false $sensorValues -}}
{{- if not (kindIs "bool" $enabled) -}}
  {{- fail "agent.sensor.receivers.profiles.ebpfProfiler.enabled must be a boolean" -}}
{{- end -}}
{{- $sensorWithoutEBPF := not (dig "ebpfEnabled" true $sensorValues) -}}
{{- range $sensorValues.env -}}
  {{- if eq (toString .name) "FLORA_EBPFENABLED" -}}
    {{- $sensorWithoutEBPF = has (tpl (toString .value) $root) (list "false" "False" "FALSE" "f" "F" "0") -}}
  {{- end -}}
{{- end -}}
{{- if and $enabled (not $root.Values.agent.gke.autopilot.enabled) (not $sensorWithoutEBPF) -}}
true
{{- end -}}
{{- end -}}

{{- define "groundcover.ebpfProfiler.controlDir" -}}
/var/run/groundcover/ebpf-profiler
{{- end -}}

{{- define "groundcover.ebpfProfiler.controlSocket" -}}
{{ include "groundcover.ebpfProfiler.controlDir" . }}/control.sock
{{- end -}}

{{- define "groundcover.ebpfProfiler.controlMount" -}}
- name: ebpf-profiler-control
  mountPath: {{ include "groundcover.ebpfProfiler.controlDir" . }}
{{- end -}}

{{- define "groundcover.ebpfProfiler.container" -}}
{{- $root := .root -}}
{{- $sensorValues := .sensorValues -}}
{{- $profiler := dig "receivers" "profiles" "ebpfProfiler" (dict) $sensorValues -}}
{{- if include "groundcover.ebpfProfiler.enabled" . -}}
  {{- $ebpfSwitchFromRef := false -}}
  {{- range $sensorValues.env -}}
    {{- if eq (toString .name) "FLORA_EBPFENABLED" -}}
      {{- $ebpfSwitchFromRef = hasKey . "valueFrom" -}}
    {{- end -}}
  {{- end -}}
  {{- if $ebpfSwitchFromRef -}}
    {{- fail "agent.sensor.receivers.profiles.ebpfProfiler.enabled requires FLORA_EBPFENABLED in agent.sensor.env to be a value, not valueFrom" -}}
  {{- end -}}
  {{- if ne (toString $sensorValues.collectionEnabled) "true" -}}
    {{- fail "agent.sensor.receivers.profiles.ebpfProfiler.enabled requires agent.sensor.collectionEnabled=true" -}}
  {{- end -}}
  {{- if ne (toString $sensorValues.ingestionEnabled) "true" -}}
    {{- fail "agent.sensor.receivers.profiles.ebpfProfiler.enabled requires agent.sensor.ingestionEnabled=true" -}}
  {{- end -}}
  {{- if ne (toString (dig "apmIngestor" "otel" "direct" "enabled" false $sensorValues)) "true" -}}
    {{- fail "agent.sensor.receivers.profiles.ebpfProfiler.enabled requires agent.sensor.apmIngestor.otel.direct.enabled=true" -}}
  {{- end -}}
  {{- if ne (toString (dig "apmIngestor" "otel" "direct" "otlp" "enabled" false $sensorValues)) "true" -}}
    {{- fail "agent.sensor.receivers.profiles.ebpfProfiler.enabled requires agent.sensor.apmIngestor.otel.direct.otlp.enabled=true" -}}
  {{- end -}}
  {{- $grpcPort := dig "apmIngestor" "otel" "direct" "otlp" "grpcPort" 0 $sensorValues | int -}}
  {{- if le $grpcPort 0 -}}
    {{- fail "agent.sensor.receivers.profiles.ebpfProfiler.enabled requires agent.sensor.apmIngestor.otel.direct.otlp.grpcPort to be greater than zero" -}}
  {{- end -}}
  {{- if ne (toString (dig "receivers" "profiles" "enabled" false $sensorValues)) "true" -}}
    {{- fail "agent.sensor.receivers.profiles.ebpfProfiler.enabled requires agent.sensor.receivers.profiles.enabled=true" -}}
  {{- end -}}
  {{- if and (eq (toString $profiler.selection) "rules") (ne (toString $root.Values.global.fleetmanager.enabled) "true") -}}
    {{- fail "agent.sensor.receivers.profiles.ebpfProfiler.selection=rules requires global.fleetmanager.enabled=true" -}}
  {{- end -}}
  {{- $samples := toString $profiler.samplesPerSecond -}}
  {{- if not (and (regexMatch "^[0-9]+$" $samples) (le 1 (atoi $samples)) (le (atoi $samples) 1000)) -}}
    {{- fail "agent.sensor.receivers.profiles.ebpfProfiler.samplesPerSecond must be a whole number from 1 to 1000" -}}
  {{- end -}}
  {{- $epoch := toDate "2006-01-02" "2000-01-01" -}}
  {{- $intervalNanos := ((dateModify (toString $profiler.reportInterval) $epoch).Sub $epoch).Nanoseconds -}}
  {{- if or (lt $intervalNanos 1000000000) (gt $intervalNanos 60000000000) -}}
    {{- fail "agent.sensor.receivers.profiles.ebpfProfiler.reportInterval must be a duration from 1s to 1m, such as 5s" -}}
  {{- end -}}
- name: ebpf-profiler
  image: {{ tpl $profiler.image.repository $root }}:{{ tpl $profiler.image.tag $root }}
  imagePullPolicy: {{ default "Always" $root.Values.agent.imagePullPolicy }}
  env:
    - name: GC_EBPF_PROFILER_SAMPLES_PER_SECOND
      value: {{ $profiler.samplesPerSecond | quote }}
    - name: GC_EBPF_PROFILER_REPORT_INTERVAL
      value: {{ $profiler.reportInterval | quote }}
    - name: GC_EBPF_PROFILER_OTLP_ENDPOINT
      value: {{ printf "127.0.0.1:%d" $grpcPort | quote }}
    - name: GC_EBPF_PROFILER_CONTROL_SOCKET
      value: {{ include "groundcover.ebpfProfiler.controlSocket" . | quote }}
  resources:
    {{- toYaml $profiler.resources | nindent 4 }}
  securityContext:
    privileged: true
  volumeMounts:
    - name: sys-kernel-debug
      mountPath: /sys/kernel/debug
    - name: sys-kernel-tracing
      mountPath: {{ include "groundcover.sensor.tracefs.mount.path" (dict "sensorValues" $sensorValues) }}
    {{- include "groundcover.ebpfProfiler.controlMount" . | nindent 4 }}
{{- end -}}
{{- end -}}
