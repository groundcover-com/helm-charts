{{/*
Expand the name of the chart.
*/}}
{{- define "shepherd.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "shepherd.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "shepherd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "shepherd.labels" -}}
helm.sh/chart: {{ include "shepherd.chart" . }}
{{ include "shepherd.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "shepherd.selectorLabels" -}}
app.kubernetes.io/name: {{ include "shepherd.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "shepherd.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "shepherd.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{- define "shepherd_secrets_certificate" -}}
{{ printf "%s-certificate" (include "shepherd.fullname" .) }}
{{- end -}}


{{- define "shepherd_scheme" -}}
{{- if and .Values.config.ingestor.TLSCertFile .Values.config.ingestor.TLSKeyFile }}
{{- printf "https" }}
{{- else}}
{{- printf "http" }}
{{- end }}
{{- end -}}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "shepherd.ingress.apiVersion" -}}
  {{- if and (.Capabilities.APIVersions.Has "networking.k8s.io/v1") -}}
      {{- print "networking.k8s.io/v1" -}}
  {{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" -}}
    {{- print "networking.k8s.io/v1beta1" -}}
  {{- else -}}
    {{- print "extensions/v1beta1" -}}
  {{- end -}}
{{- end -}}

{{/*
Return if ingress is stable.
*/}}
{{- define "shepherd.ingress.isStable" -}}
  {{- eq (include "shepherd.ingress.apiVersion" .) "networking.k8s.io/v1" -}}
{{- end -}}

{{/*
Return if ingress supports ingressClassName.
*/}}
{{- define "shepherd.ingress.supportsIngressClassName" -}}
  {{- or (eq (include "shepherd.ingress.isStable" .) "true") (and (eq (include "shepherd.ingress.apiVersion" .) "networking.k8s.io/v1beta1")) -}}
{{- end -}}

{{/*
Return if ingress supports pathType.
*/}}
{{- define "shepherd.ingress.supportsPathType" -}}
  {{- or (eq (include "shepherd.ingress.isStable" .) "true") (and (eq (include "shepherd.ingress.apiVersion" .) "networking.k8s.io/v1beta1")) -}}
{{- end -}}