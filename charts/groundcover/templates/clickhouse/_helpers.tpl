{{- define "clickhouse.fullname" -}}
{{- printf "%s-clickhouse" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- /*
  Do NOT define "clickhouse.headlessServiceName" here: named templates are
  global, and this would shadow the Bitnami subchart's own definition of it,
  breaking the aliased standby instance's headless Service DNS.
*/ -}}

{{- define "clickhouse.database" -}}
{{-  print "groundcover" -}}
{{- end -}}

{{- define "clickhouse.username" -}}
{{-  print "default" -}}
{{- end -}}

{{- define "clickhouse.readerUsername" -}}
{{-  print "reader" -}}
{{- end -}}

{{- define "clickhouse.nativePort" -}}
{{- .Values.global.clickhouse.containerPorts.tcp | default "9000" -}}
{{- end -}}

{{- define "clickhouse.password" -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "clickhouse.secretName" .) | default dict) -}}
{{- if .Values.global.clickhouse.auth.password -}}
    {{- .Values.global.clickhouse.auth.password -}}
{{- else if $secret.data -}}
    {{- index $secret.data (include "clickhouse.secretKey" .) | b64dec -}}
{{- else if .Values.global.clickhouse.auth.existingSecret -}}
    {{- /* Externally-managed secret that isn't readable in this render (e.g. a
           dry-run, where lookup returns nothing). Never fall back to randAlphaNum
           here: with an existingSecret the chart isn't the source of truth, and a
           fresh random value each render churns every checksum/clickhouse-secret
           annotation and rolls the consumer pods on every reconcile. Return a
           stable token instead so the checksum is deterministic. */ -}}
    {{- printf "existing-%s" (include "clickhouse.secretName" .) -}}
{{- else -}}
    {{- randAlphaNum 16 -}}
{{- end -}}
{{- end -}}

{{/*
Dedicated read-only ClickHouse user the schema-managed dictionaries
authenticate with when global.clickhouse.dictionaryUser.enabled is set. Created
by db-manager on boot (CREATE USER IF NOT EXISTS + GRANT SELECT); its password
comes from the dedicated secret below, NOT the rotating admin secret, so admin
password rotations never invalidate dictionary credentials.
*/}}
{{- define "clickhouse.dictionaryUsername" -}}
{{- default "dictionary_reader" .Values.global.clickhouse.dictionaryUser.username -}}
{{- end -}}

{{- define "clickhouse.dictionaryUserSecretName" -}}
{{- default (printf "%s-dictionary-user" (include "clickhouse.fullname" .)) .Values.global.clickhouse.dictionaryUser.existingSecret -}}
{{- end -}}

{{- define "clickhouse.dictionaryUserSecretKey" -}}
{{- .Values.global.clickhouse.dictionaryUser.existingSecretKey -}}
{{- end -}}

{{- define "clickhouse.dictionaryUserPassword" -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "clickhouse.dictionaryUserSecretName" .) | default dict) -}}
{{- if $secret.data -}}
    {{- index $secret.data (include "clickhouse.dictionaryUserSecretKey" .) | b64dec -}}
{{- else -}}
    {{- randAlphaNum 24 -}}
{{- end -}}
{{- end -}}

{{- define "clickhouse.nativeEndpoint" -}}
{{-  printf "clickhouse://%s:%d" (include "clickhouse.fullname" .) (include "clickhouse.nativePort" . | int ) -}}
{{- end -}}

{{- define "clickhouse.httpEndpoint" -}}
{{-  printf "http://%s:%d" (include "clickhouse.fullname" .) (.Values.global.clickhouse.containerPorts.http | int ) -}}
{{- end -}}

{{- define "clickhouse.shard0Name" -}}
{{ printf "%s-shard0-0-external" (include "clickhouse.fullname" $) | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{- define "clickhouse.shard0HttpEndpoint" -}}
{{ printf "http://%s:%d" (include "clickhouse.shard0Name" $) (.Values.global.clickhouse.containerPorts.http | int ) }}
{{- end -}}

{{- define "clickhouse.proxyServiceName" -}}
{{- $name := "" -}}
{{- if .Values.clickhouseProxy -}}
{{- $name = (.Values.clickhouseProxy.service | default dict).name -}}
{{- end -}}
{{- if $name -}}
{{- if or (gt (len $name) 63) (not (regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" $name)) -}}
{{- fail (printf "clickhouseProxy.service.name %q must be a valid RFC 1123 DNS label (lowercase alphanumerics and '-', starting/ending with an alphanumeric, max 63 chars)" $name) -}}
{{- end -}}
{{- $name -}}
{{- else -}}
{{- printf "%s-clickhouse-proxy" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "clickhouse.readHost" -}}
{{- if (.Values.global.clickhouse.ha | default dict).enabled -}}
{{- include "clickhouse.proxyServiceName" . -}}
{{- else -}}
{{- include "clickhouse.fullname" . -}}
{{- end -}}
{{- end -}}

{{- define "clickhouse.readHostShard0" -}}
{{- if (.Values.global.clickhouse.ha | default dict).enabled -}}
{{- include "clickhouse.proxyServiceName" . -}}
{{- else -}}
{{- include "clickhouse.shard0Name" . | trim -}}
{{- end -}}
{{- end -}}

{{- define "clickhouse.extraShardsList" -}}
{{- if kindIs "slice" .Values.dbManager.extraShardsOverride }}
{{- .Values.dbManager.extraShardsOverride | toYaml | nindent 2 }}
{{- else }}
{{- $shards := $.Values.clickhouse.shards | int }}
{{- $list := list -}}
{{- range $shard, $e := until $shards }}
{{- if ne $e 0}}
{{- $item := printf "%s-shard%d-%d-external" (include "clickhouse.fullname" $) $shard 0 | trunc 63 | trimSuffix "-" }}
{{- $list = append $list $item }}
{{- end -}}
{{- end -}}
{{- $list | toYaml | nindent 2 }}
{{- end -}}
{{- end -}}

{{- define "clickhouse.opentelemetrySpanLogSetting" -}}
{{ if eq .Values.disableOpentelemetrySpanLog false }}
{{- else -}}
<opentelemetry_span_log remove="1"/>
{{- end -}}
{{- end -}}

{{/*
Generalized statefulset-modifier pre-upgrade hooks for a clickhouse-shaped
StatefulSet (primary or the standby alias). Extracted from what used to be
templates/clickhouse/hooks.yaml verbatim - only variable references were
parameterized, control flow is unchanged. Params (all required):
  root: the top-level "." context ($) - named templates lose it otherwise.
  valuesKey: "clickhouse" or "clickhouse-standby" - looked up via index
    since the alias key is hyphenated.
  fullnameTemplate: name of the fullname helper to include ("clickhouse.fullname"
    or "clickhouse.standby.fullname").
  jobSuffix: short suffix for hook Job names, unique across callers sharing
    one statefulset-modifier ServiceAccount ("ch" / "ch-standby").
  nameOverrideDefault: fallback value for the "app.kubernetes.io/name" selector
    label when valuesKey's own nameOverride is unset ("clickhouse" /
    "clickhouse-standby") - only affects the live-lookup selector-drift check.
*/}}
{{- define "clickhouse.statefulsetModifierHooks" -}}
{{- $root := .root -}}
{{- $vals := index $root.Values .valuesKey -}}
{{- $fullnameTemplate := .fullnameTemplate -}}
{{- $jobSuffix := .jobSuffix -}}
{{- $nameOverrideDefault := .nameOverrideDefault -}}
{{- $statefulsetShardSelector := default dict $vals.statefulsetShardSelector -}}
{{- $selectorEnabled := default false $statefulsetShardSelector.enabled -}}
{{ if and ($root.Values.global.backend.enabled) (or (and ($vals.persistence.enabled) (index $root.Values "statefulset-modifier" "enabled")) $root.Release.IsUpgrade) (not ($vals.persistence.dropBeforeCreate)) }}
{{- $shouldPatchSize := (index $root.Values "statefulset-modifier" "sizePatches") -}}
{{- $shards := $vals.shards | int -}}
{{- $annotations := $vals.persistence.annotations | toJson -}}
{{- range $shardIndex, $e := until $shards -}}
{{- $shouldPatchPvc := false -}}
{{- $shouldPatchAnnotations := false -}}
{{- $shouldPatchSelector := false -}}
{{- /* Per-shard PVC sizing: shardSizes takes precedence, then extraShardsSize for non-zero shards, then default size */ -}}
{{- $shardSizes := $vals.persistence.shardSizes | default dict -}}
{{- $shardKey := printf "shard%d" $shardIndex -}}
{{- $pvcSize := "" -}}
{{- if hasKey $shardSizes $shardKey -}}
  {{- $pvcSize = index $shardSizes $shardKey -}}
{{- else if eq $shardIndex 0 -}}
  {{- $pvcSize = $vals.persistence.size -}}
{{- else -}}
  {{- $pvcSize = default $vals.persistence.size $vals.persistence.extraShardsSize -}}
{{- end -}}
{{- $patches := (include "volume-expansion.patches" (merge (dict "size" $pvcSize) $vals.persistence) ) | fromYaml -}}
{{- $sizePatches := (include "volume-expansion.size-patches" (merge (dict "size" $pvcSize) $vals.persistence) ) | fromYaml -}}
{{- $annotationsPatches := (include "volume-expansion.annotations-patches"  $vals.persistence) | fromYaml -}}
{{- $sizePvcPatch := (get $sizePatches "pvc") | toJson -}}
{{- $sizeStsPatch := (get $sizePatches "sts") | toJson -}}
{{- $annotationsPvcPatch := (get $annotationsPatches "pvc") | toJson -}}
{{- $annotationsStsPatch := (get $annotationsPatches "sts") | toJson -}}
{{- $pvcPatch := (get $patches "pvc") | toJson -}}
{{- $stsPatch := (get $patches "sts") | toJson -}}
{{- $stsName := (printf "%s-shard%d" (include $fullnameTemplate $root) $shardIndex) -}}
{{- $name := (include "statefulset-modifier.jobName" (dict "name" (printf "%s-%s-%d" (include "statefulset-modifier.fullname" $root) $jobSuffix $shardIndex))) -}}
{{- $pvcName := (printf "data-%s-0" $stsName) -}}
{{ if $root.Release.IsUpgrade }}
{{- $sts := (lookup "apps/v1" "StatefulSet" $root.Release.Namespace $stsName | default dict) -}}
{{- if and $vals.persistence.enabled (index $root.Values "statefulset-modifier" "enabled") }}
{{- $pvc := (lookup "v1" "PersistentVolumeClaim" $root.Release.Namespace $pvcName | default dict) -}}
{{- $pvcCapacitySize := ($pvc | dig "status" "capacity" "storage" $pvcSize) -}}
{{- $stsPvcSize := ($sts | dig "spec" "volumeClaimTemplates" (list dict) | first | dig "spec" "resources" "requests" "storage" $pvcSize) -}}
{{- $stsPvcAnnotations := ($sts | dig "spec" "volumeClaimTemplates" (list dict) | first | dig "metadata" "annotations" dict) | toJson -}}
{{- $shouldPatchPvc = (not (eq $pvcSize $pvcCapacitySize)) -}}
{{- $shouldPatchAnnotations = (not (eq $stsPvcAnnotations $annotations)) -}}
{{- end -}}
{{- if hasKey $sts "metadata" }}
{{- $renderedPodLabels := include "common.tplvalues.merge" (dict "values" (list ($vals.podLabels | default dict) ($vals.commonLabels | default dict)) "context" $root) | fromYaml | default dict -}}
{{- $desiredSelectorLabels := merge (pick $renderedPodLabels "app.kubernetes.io/name" "app.kubernetes.io/instance" "helm.sh/chart" "app.kubernetes.io/managed-by") (dict "app.kubernetes.io/name" (default $nameOverrideDefault $vals.nameOverride) "app.kubernetes.io/instance" $root.Release.Name) -}}
{{- $_ := set $desiredSelectorLabels "app.kubernetes.io/component" "clickhouse" -}}
{{- if eq (toString $selectorEnabled) "true" }}
{{- $_ := set $desiredSelectorLabels "shard" (toString $shardIndex) -}}
{{- end }}
{{- $stsSelectorLabels := ($sts | dig "spec" "selector" "matchLabels" dict) -}}
{{- $shouldPatchSelector = (not (eq ($stsSelectorLabels | toJson) ($desiredSelectorLabels | toJson))) -}}
{{- end -}}
{{- else -}}
{{- $shouldPatchPvc = and $vals.persistence.enabled (index $root.Values "statefulset-modifier" "enabled") -}}
{{- $shouldPatchAnnotations = and $vals.persistence.enabled (index $root.Values "statefulset-modifier" "enabled") -}}
{{- $shouldPatchSelector = false -}}
{{- end -}}
{{ if or (and $shouldPatchPvc $shouldPatchSize) $shouldPatchAnnotations $shouldPatchSelector }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ $name }}
  labels:
  annotations:
  {{- include "statefulset-modifier.job.annotations" $root | nindent 4 }}
spec:
  backoffLimit: 0
  template:
    metadata:
      name: {{ $name }}
    spec:
      restartPolicy: Never
      imagePullSecrets: {{ include "imagePullSecrets" $root }}
      serviceAccountName: {{ include "statefulset-modifier.fullname" $root }}
      containers:
      - name: sts-delete
        imagePullPolicy: IfNotPresent
        image: {{ include "statefulset-modifier.job.image" $root }}
        command:
          - /bin/sh
          - -c
          - |
            set -e
            kubectl delete sts {{ $stsName | quote }} --ignore-not-found --cascade=orphan
{{ if and $shouldPatchPvc $shouldPatchSize }}
      - name: pvc-patch-size-and-annotations
        imagePullPolicy: IfNotPresent
        image: {{ include "statefulset-modifier.job.image" $root }}
        command:
          - /bin/sh
          - -c
          - |
            set -e
            kubectl patch pvc {{ $pvcName | quote }} --type json --patch {{ $pvcPatch | quote }} || exit 0
{{ else if $shouldPatchAnnotations }}
      - name: pvc-patch-annotations-only
        imagePullPolicy: IfNotPresent
        image: {{ include "statefulset-modifier.job.image" $root }}
        command:
          - /bin/sh
          - -c
          - |
            set -e
            kubectl patch pvc {{ $pvcName | quote }} --type json --patch {{ $annotationsPvcPatch | quote }} || exit 0
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{ if and ($root.Values.global.backend.enabled) (index $root.Values "statefulset-modifier" "enabled") ($vals.persistence.enabled) ($vals.persistence.dropBeforeCreate) }}
{{- $shards := $vals.shards | int -}}
{{- range $shardIndex, $e := until $shards -}}
{{- $hookJobName := (include "statefulset-modifier.jobName" (dict "name" (printf "%s-%s-delete-sts-hook-%d" (include "statefulset-modifier.fullname" $root) $jobSuffix $shardIndex))) -}}
{{- $stsName := (printf "%s-shard%d" (include $fullnameTemplate $root) $shardIndex) }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ $hookJobName }}
  annotations:
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-delete-policy": "before-hook-creation"
spec:
  template:
    spec:
      restartPolicy: Never
      imagePullSecrets: {{ include "imagePullSecrets" $root }}
      serviceAccountName: {{ include "statefulset-modifier.fullname" $root }}
      containers:
        - name: kubectl
          image: {{ include "statefulset-modifier.job.image" $root }}
          command:
            - sh
            - -c
            - |
              set -e
              kubectl delete sts {{ $stsName | quote }} --cascade=foreground
{{- end }}
{{- end }}
{{- end -}}

