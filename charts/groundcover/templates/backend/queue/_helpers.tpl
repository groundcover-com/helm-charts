{{- define "queue.enabled" -}}
{{- if and .Values.global.backend.enabled .Values.global.queue.enabled -}}true{{- end -}}
{{- end -}}

{{/* Labels and selectors keep the short name; only resource names carry the release. */}}
{{- define "queue.name" -}}
queue
{{- end -}}

{{- define "queue.fullname" -}}
{{- printf "%s-queue" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "queue.configMapName" -}}
{{- printf "%s-config" (include "queue.fullname" .) -}}
{{- end -}}

{{/*
Container ports. The rendered config's listen addresses are generated from these
so the probes, Service and process cannot disagree.
*/}}
{{- define "queue.httpPort" -}}
4318
{{- end -}}

{{- define "queue.grpcPort" -}}
4317
{{- end -}}

{{- define "queue.labels" -}}
{{- include "groundcover.labels" . }}
app: {{ include "queue.name" . }}
app.kubernetes.io/name: {{ include "queue.name" . }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- with .Values.queue.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "queue.selectorLabels" -}}
app: {{ include "queue.name" . }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

{{- define "queue.image" -}}
{{- $img := .Values.queue.image -}}
{{- printf "%s/%s:%s" (tpl $img.registry .) (tpl $img.repository .) (tpl (toString $img.tag) .) -}}
{{- end -}}

{{/*
ServiceAccount the pods run under. A dedicated one is created by default;
set serviceAccount.create=false and serviceAccount.name to reuse an existing
account (e.g. one whose cloud role already grants PutObject on the bucket).
*/}}
{{- define "queue.serviceAccountName" -}}
{{- $sa := .Values.queue.serviceAccount -}}
{{- if $sa.create -}}
{{- default (include "queue.fullname" .) $sa.name -}}
{{- else -}}
{{- default "default" $sa.name -}}
{{- end -}}
{{- end -}}

{{/*
The queue only implements S3 (and S3-compatible stores), so unlike
bucket-streamer there is no provider to infer: the bucket follows
vector.objectStorage.s3Bucket under the same producer guard
(allowed: true), unless queue.objectStore.bucket names one explicitly.
*/}}
{{- define "queue.objectStore.bucket" -}}
{{- $os := .Values.queue.objectStore -}}
{{- $vos := .Values.vector.objectStorage -}}
{{- if $os.bucket -}}
{{- tpl $os.bucket . -}}
{{- else if and $vos.allowed $vos.s3Bucket -}}
{{- $vos.s3Bucket -}}
{{- else -}}
{{- fail "queue: no S3 bucket to write to - set queue.objectStore.bucket, or configure vector.objectStorage with allowed: true and s3Bucket (the queue supports S3 and S3-compatible stores only)" -}}
{{- end -}}
{{- end -}}

{{/*
Both regions unset leaves `default` returning nil, which include stringifies as
Helm's `<no value>` sentinel; collapse it to an empty string so callers can guard.
*/}}
{{- define "queue.objectStore.region" -}}
{{- $region := default .Values.vector.objectStorage.region .Values.queue.objectStore.region -}}
{{- if $region -}}{{- $region -}}{{- end -}}
{{- end -}}

{{- define "queue.config" -}}
{{- $q := .Values.queue -}}
{{- $store := dict "provider" "s3" "bucket" (include "queue.objectStore.bucket" .) -}}
{{- with include "queue.objectStore.region" . }}
{{- $_ := set $store "region" . }}
{{- end }}
{{- with $q.objectStore.endpoint }}
{{- $_ := set $store "endpoint" (tpl . $) }}
{{- end }}
{{- if eq (toString $q.objectStore.pathStyle) "true" }}
{{- $_ := set $store "path_style" true }}
{{- end }}
{{- $server := dict "listen_address" (printf ":%s" (include "queue.httpPort" .)) "grpc_listen_address" (printf ":%s" (include "queue.grpcPort" .)) }}
{{- $generated := dict "server" $server "store" $store }}
{{- $user := dict }}
{{- with $q.config }}
{{- $user = fromYaml (tpl (toYaml .) $) }}
{{- end }}
{{- toYaml (merge $generated $user) }}
{{- end -}}
