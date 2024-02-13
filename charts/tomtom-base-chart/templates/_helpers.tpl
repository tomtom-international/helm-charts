{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tomtom-base-chart.fullname" -}}
{{- if .Values.advancedSettings.fullnameOverride }}
{{- .Values.advancedSettings.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tomtom-base-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tomtom-base-chart.labels" -}}
helm.sh/chart: {{ include "tomtom-base-chart.chart" . }}
{{ include "tomtom-base-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
based-on: tomtom-generic-helm-chart
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tomtom-base-chart.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "tomtom-base-chart.serviceAccountName" -}}
{{- if .Values.advancedSettings.serviceAccount.create }}
{{- default (include "tomtom-base-chart.fullname" .) .Values.advancedSettings.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.advancedSettings.serviceAccount.name }}
{{- end }}
{{- end }}
