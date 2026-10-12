{{- define "monitors-service.fullname" -}}
{{- printf "%s-monitors-service" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Container env shared by the deployment and the reconcile CronJob. */}}
{{- define "monitors-service.containerEnv" -}}
env:
- name: GC_GROUNDCOVERVERSION
  valueFrom:
    fieldRef:
      fieldPath: metadata.annotations['groundcover_version']
{{- if eq (include "telemetry.enabled" .) "true" }}
- name: GC_TRACING_HEADERS_APIKEY
  valueFrom:
    secretKeyRef:
      key: {{ template "groundcover.apikeySecretKey" . }}
      name: {{ template "groundcover.apikeySecretName" . }}
{{- end }}
- name: GC_POSTGRES_PASS
  valueFrom:
    secretKeyRef:
      name: {{ include "postgresql.secretName" . }}
      key: {{ include "postgresql.adminPasswordKey" . }}
{{- with .Values.monitorsService.env }}
{{ tpl (toYaml .) $ }}
{{- end }}
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
envFrom:
  - secretRef:
      name: {{include "groundcover.config.secretName" .}}
image: {{ tpl .Values.monitorsService.image.repository . }}:{{ tpl .Values.monitorsService.image.tag . }}
imagePullPolicy: Always
{{- end -}}

{{/* Pod placement shared by the deployment and the reconcile CronJob. */}}
{{- define "monitors-service.podPlacement" -}}
{{- if .Values.monitorsService.tolerations }}
tolerations:
{{ toYaml .Values.monitorsService.tolerations | indent 2 }}
{{- end }}
{{- if .Values.monitorsService.affinity }}
affinity:
{{ toYaml .Values.monitorsService.affinity | indent 2 }}
{{- end }}
{{- if .Values.monitorsService.nodeSelector }}
nodeSelector:
{{ toYaml .Values.monitorsService.nodeSelector | indent 2 }}
{{- end }}
imagePullSecrets: {{ include "imagePullSecrets" . }}
{{- if .Values.monitorsService.priorityClassName }}
priorityClassName: {{ .Values.monitorsService.priorityClassName }}
{{- end }}
{{- end -}}

{{- define "monitors-service.configVolume" -}}
- configMap:
    name: monitors-service-config
  name: monitors-service-config-volume
{{- end -}}

{{- define "monitors-service.configVolumeMount" -}}
- mountPath: /etc/monitors-service
  name: monitors-service-config-volume
{{- end -}}
