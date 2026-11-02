{{- define "sensor.fullname" -}}
    {{- printf "%s-sensor" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sensorDaemonSet.fullname" -}}
    {{- if .Values.agent.randomSuffixName -}}
        {{- printf "%s-%s" (include "sensor.fullname" . | trunc 58 ) (randAlphaNum 4 | lower) -}}
    {{- else -}}
        {{- include "sensor.fullname" . -}}
    {{- end -}}
{{- end -}}

{{- define "sensor.metric-ingestor-hostname" -}}
    {{- printf "%s-metric-ingestor" (include "sensor.fullname" .) -}}
{{- end -}}
{{- define "alligator.fullname" -}}
    {{- printf "%s-alligator" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sensor.profiles.validate" -}}
    {{- $names := dict -}}
    {{- $agentSelector := .Values.agent.nodeSelector | default dict -}}
    {{- range .Values.agent.extraSensorProfiles -}}
        {{- if not (regexMatch "^[a-z0-9]([-a-z0-9]{0,20}[a-z0-9])?$" (toString .name)) -}}
            {{- fail (printf "agent.extraSensorProfiles: name %q must be a lowercase RFC 1123 label of at most 22 characters" (toString .name)) -}}
        {{- end -}}
        {{- if hasKey $names .name -}}
            {{- fail (printf "agent.extraSensorProfiles: name %q is used more than once" .name) -}}
        {{- end -}}
        {{- $_ := set $names .name true -}}
        {{- $name := .name -}}
        {{- range $key, $value := .nodeSelector -}}
            {{- if not (kindIs "string" $value) -}}
                {{- fail (printf "agent.extraSensorProfiles: profile %q nodeSelector value for %q must be a string; quote numeric and boolean values" $name $key) -}}
            {{- end -}}
            {{- if and (hasKey $agentSelector $key) (not (deepEqual (get $agentSelector $key) $value)) -}}
                {{- fail (printf "agent.extraSensorProfiles: profile %q nodeSelector key %q conflicts with agent.nodeSelector" $name $key) -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if and .Values.agent.extraSensorProfiles .Values.agent.gke.autopilot.enabled -}}
        {{- fail "agent.extraSensorProfiles is not supported on GKE Autopilot" -}}
    {{- end -}}
{{- end -}}

{{- define "sensor.profile.suffix" -}}
    {{- with .name -}}-{{ . }}{{- end -}}
{{- end -}}

{{- define "sensor.profile.values" -}}
    {{- $sensorValues := deepCopy .root.Values.agent.sensor -}}
    {{- if .root.Values.agent.alligator -}}
        {{- $sensorValues = mergeOverwrite $sensorValues (deepCopy .root.Values.agent.alligator) -}}
    {{- end -}}
    {{- with .profile.sensor -}}
        {{- $sensorValues = mergeOverwrite $sensorValues (deepCopy .) -}}
    {{- end -}}
    {{- $_ := set .out "sensorValues" $sensorValues -}}
{{- end -}}

{{- define "sensor.profile.nodeSelector" -}}
    {{- $nodeSelector := .root.Values.agent.nodeSelector | default dict -}}
    {{- with .profile.nodeSelector -}}
        {{- $nodeSelector = merge (deepCopy .) $nodeSelector -}}
    {{- end -}}
    {{- with $nodeSelector -}}{{- toYaml . -}}{{- end -}}
{{- end -}}

{{- define "sensor.profile.affinity" -}}
    {{- with (.profile.affinity | default .root.Values.agent.affinity) -}}{{- toYaml . -}}{{- end -}}
{{- end -}}
