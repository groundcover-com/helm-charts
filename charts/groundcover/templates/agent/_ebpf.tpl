{{- define "groundcover.sensor.ebpfMode" -}}
{{- $mode := dig "ebpfMode" "" .sensorValues -}}
{{- if not (kindIs "string" $mode) -}}
  {{- fail "agent.sensor.ebpfMode must be one of: empty, enabled, disabled, auto" -}}
{{- end -}}
{{- $mode = lower (trim $mode) -}}
{{- if not (has $mode (list "" "enabled" "disabled" "auto")) -}}
  {{- fail "agent.sensor.ebpfMode must be one of: empty, enabled, disabled, auto" -}}
{{- end -}}
{{- $mode -}}
{{- end -}}
