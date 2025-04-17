{{- define "common.render" -}}
{{- $values := (get . "$").Values }}
{{- $spec := mergeOverwrite (dict "name" .name "common" $values.common "Values" $values) (deepCopy (get $values.common .type)) (deepCopy .spec) }}
{{- $content := include (printf "common.%s" (lower .type)) $spec }}
{{ tpl $content (merge (dict "name" .name "Template" (dict "BasePath" "<inline>" "Name" "<noname>")) (deepCopy $spec) (get . "$")) }}
{{- end -}}

{{- define "common.to-yaml" -}}
{{ (omit . "name" "common" "Values" "Release" "Template") | toYaml }}
{{- end -}}
