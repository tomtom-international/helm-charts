{{- define "common.render" -}}
{{- $values := (get . "$").Values }}
{{- $spec := mergeOverwrite (deepCopy (get $values.common .type)) .spec (dict "name" .name "common" $values.common "Values" $values) }}
{{- $content := include (printf "common.%s" (lower .type)) $spec }}
{{ tpl $content (merge (deepCopy $spec) (dict "name" .name "Template" (dict "BasePath" "<inline>" "Name" "<noname>")) (get . "$")) }}
{{- end -}}

{{- define "common.to-yaml" -}}
{{ (omit . "name" "common" "Values" "Release" "Template") | toYaml }}
{{- end -}}

{{- define "common.target-ref" -}}
{{- $targetVersions := dict "Deployment" "apps/v1" -}}
apiVersion: {{ get $targetVersions .type }}
kind: {{ .type }}
name: {{ .name }}
{{- end -}}
