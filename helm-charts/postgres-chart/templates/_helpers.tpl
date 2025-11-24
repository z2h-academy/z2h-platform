{{- define "postgres-chart.name" -}}
{{ .Chart.Name }}
{{- end -}}

{{- define "postgres-chart.fullname" -}}
{{ include "postgres-chart.name" . }}
{{- end -}}

