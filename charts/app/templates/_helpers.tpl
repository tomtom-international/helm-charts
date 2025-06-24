{{- define "common.render" -}}
{{- $values := (get . "$").Values }}
{{- $spec := mergeOverwrite (dict "name" .name "common" $values.common "Values" $values) (deepCopy (get $values.common .type)) (deepCopy .spec) }}
{{- $content := include (printf "common.%s" (lower .type)) $spec }}
{{ tpl $content (merge (dict "name" .name "Template" (dict "BasePath" "<inline>" "Name" "<noname>")) (deepCopy $spec) (get . "$")) }}
{{- end -}}

{{- define "common.render-spec" -}}
{{- toYaml (omit . "name" "namespace" "labels" "annotations" "common" "Values") }}
{{- end -}}

{{- define "common.to-list" -}}
{{- if kindIs "slice" . }}
{{ toYaml . }}
{{- else }}
{{- if kindIs "slice" (get . "$values") }}
{{ toYaml (get . "$values") }}
{{- else }}
  {{- $hasKey := or (not (hasKey . "$keyAt")) (get . "$keyAt") }}
  {{- $key := get . "$keyAt" | default "name" -}}
  {{- $value := get . "$valueAt" | default "value" -}}
  {{- $values := get . "$values" | default . -}}
  {{- $common := get . "$common" | default dict -}}
  {{- $helper := get . "$helper" -}}
  {{- $lst := list }}
  {{- range $k := keys $values | sortAlpha }}
    {{- $v := get $values $k }}
    {{- if not $v }}{{ continue }}{{ end }}
    {{- if kindIs "string" $v }}{{ $path := regexSplit "\\." $value -1 | reverse }}{{ range $x := $path }}{{ $v = dict $x $v }}{{ end }}{{ end }}
    {{- if $hasKey }}{{ $v = mergeOverwrite (dict $key $k) $v }}{{ end }}
    {{- $v = mergeOverwrite (deepCopy $common) $v }}
    {{- if $helper }}{{ $v = include $helper $v | fromYaml }}{{ end }}
    {{- $lst = append $lst $v }}
  {{- end }}
{{- toYaml $lst }}
{{- end }}
{{- end }}
{{- end -}}
