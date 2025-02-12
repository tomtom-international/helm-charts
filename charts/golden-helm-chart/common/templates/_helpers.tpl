{{- define "common.target-ref" -}}
{{- $targetVersions := dict "Deployment" "apps/v1" -}}
apiVersion: {{ get $targetVersions .type }}
kind: {{ .type }}
name: {{ .name }}
{{- end -}}
