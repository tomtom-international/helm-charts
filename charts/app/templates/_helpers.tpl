{{/*
Renders manifests from a dict of resources, with defaults sources from common values and default resource name set to dict key.
Passes original .Values and .common Helm values to a corresponding manifest template or uses default renderer.
Performs post-rendering using rendering output as plain Go template with global $ Helm context.
*/}}
{{- define "common.render" -}}
---
apiVersion: {{ .apiVersion }}
kind: {{ .kind }}
{{- $dollar := get . "$" }}
{{- $common := deepCopy $dollar.Values.common }}
{{- $manifest := mergeOverwrite (deepCopy (get $common .type | default dict)) (deepCopy .manifest) (dict "common" $common) }}
{{- $_ := set $manifest "metadata" (merge ($manifest.metadata | default dict) $common.metadata (dict "name" .name)) }}
{{- if .extended }}{{ $_ := include (printf "common.%s" (lower .type)) $manifest }}{{ end }}
{{- $content := include "common.render-manifest" $manifest }}
{{- tpl $content (merge (dict "name" .name "Template" (dict "BasePath" "<inline>" "Name" "<noname>")) $manifest $dollar) }}
{{- end -}}

{{/*
Renders manifest's metadata.
*/}}
{{- define "common.render-metadata" -}}
{{- $metadata := . -}}
{{- range $k, $v := $metadata }}{{ if not $v }}{{ $_ := unset $metadata $k }}{{ end }}{{ end }}
metadata: {{- toYaml $metadata | nindent 2 }}
{{- end -}}

{{/*
Renders a manifest.
*/}}
{{- define "common.render-manifest" -}}
{{- include "common.render-metadata" .metadata }}
{{- $manifest := omit . "metadata" "common" }}
{{ if $manifest }}{{ toYaml $manifest }}{{ end }}
{{- end -}}

{{/*
Expands a dict of objects to a list of objects.
By default, expands input object to list of {name, **} objects or {name, value} objects (if dict value is a string).
Input can be parameterised to control expander strategies beyond predefined heuristics.
Parameters:
- $values - dict to expand.
- $keyAt - which field to transfer dict key to in destination object. Use `null` to drop field. Default field - `name`.
- $valueAt - which field to transfer dict value to in destination object. Can be used to specify generate nested objects,
  for example "remoteRef.key". Default - `null`, meaning no nesting.
- $common - set of fields to use as default when generating destination objects from input dict values.
- $helper - use a dedicated helper to pre-process each output object.
*/}}
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
  {{- if and (hasKey . "$values") (not (get . "$values")) }}{{ $values = dict }}{{ end }}
  {{- $common := get . "$common" | default dict -}}
  {{- $helper := get . "$helper" -}}
  {{- $lst := list }}
  {{- range $k := keys $values | sortAlpha }}
    {{- $v := get $values $k }}
    {{- if not $v }}{{ continue }}{{ end }}
    {{- if kindIs "string" $v }}{{ $path := regexSplit "\\." $value -1 | reverse }}{{ range $x := $path }}{{ $v = dict $x $v }}{{ end }}{{ end }}
    {{- if $hasKey }}{{ $v = mergeOverwrite (dict $key $k) $v }}{{ end }}
    {{- $_ := mergeOverwrite $v (deepCopy $common) $v }}
    {{- if $helper }}{{ $_ := include $helper $v }}{{ end }}
    {{- $lst = append $lst $v }}
  {{- end }}
{{- toYaml $lst }}
{{- end }}
{{- end }}
{{- end -}}
