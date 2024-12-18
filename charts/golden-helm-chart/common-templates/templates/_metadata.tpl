
{{- define "common-templates.labels" -}}
helm.sh/chart: {{ include "common-templates.chartRef" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "common-templates.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end }}
