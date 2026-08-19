{{/*
Expand the name of the chart.
*/}}
{{- define "of-dl.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "of-dl.fullname" -}}
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
{{- define "of-dl.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "of-dl.labels" -}}
helm.sh/chart: {{ include "of-dl.chart" . }}
{{ include "of-dl.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "of-dl.selectorLabels" -}}
app.kubernetes.io/name: {{ include "of-dl.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the Secret holding the Widevine CDM device keys.
*/}}
{{- define "of-dl.cdmSecretName" -}}
{{- if .Values.cdm.existingSecret }}
{{- .Values.cdm.existingSecret }}
{{- else }}
{{- printf "%s-cdm" (include "of-dl.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Whether CDM keys are available at all, from either source.
*/}}
{{- define "of-dl.hasCdm" -}}
{{- if or .Values.cdm.existingSecret (and .Values.cdm.deviceClientIdBlob .Values.cdm.devicePrivateKey) }}true{{- end }}
{{- end }}

{{/*
Name of the PersistentVolumeClaim backing /config.
*/}}
{{- define "of-dl.configClaimName" -}}
{{- if .Values.persistence.existingClaim }}
{{- .Values.persistence.existingClaim }}
{{- else }}
{{- printf "%s-config-pvc" (include "of-dl.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Render a single HOCON value. Strings are quoted, booleans and numbers are bare,
lists become [a, b, c], and a null becomes an empty string.
*/}}
{{- define "of-dl.hoconValue" -}}
{{- if kindIs "invalid" . -}}
""
{{- else if kindIs "string" . -}}
{{ . | quote }}
{{- else if kindIs "slice" . -}}
[{{ range $i, $e := . }}{{ if $i }}, {{ end }}{{ include "of-dl.hoconValue" $e }}{{ end }}]
{{- else -}}
{{ . }}
{{- end -}}
{{- end -}}

{{/*
Render a map as HOCON. Nested maps become braced blocks; everything else becomes
`key = value`. Helm iterates maps in key order, so the output is stable.
*/}}
{{- define "of-dl.hocon" -}}
{{- range $key, $value := . }}
{{- if kindIs "map" $value }}
{{- $inner := include "of-dl.hocon" $value | trim }}
{{ $key }} {
{{- if $inner }}{{ $inner | nindent 2 }}{{ end }}
}
{{- else }}
{{ $key }} = {{ include "of-dl.hoconValue" $value }}
{{- end }}
{{- end }}
{{- end -}}
