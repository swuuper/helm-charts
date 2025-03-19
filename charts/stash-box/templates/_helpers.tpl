{{/*
Expand the name of the chart.
*/}}
{{- define "stash-box.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "stash-box.fullname" -}}
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
{{- define "stash-box.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "stash-box.labels" -}}
helm.sh/chart: {{ include "stash-box.chart" . }}
{{ include "stash-box.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "stash-box.selectorLabels" -}}
app.kubernetes.io/name: {{ include "stash-box.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "stash-box.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "stash-box.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "stash-box.environment" -}}
env:
  {{- with .env }}
  {{ toYaml . | nindent 2 }}
  {{- end }}
  {{- if .Values.postgres.credentials }}
  - name: POSTGRES_USER
  {{- if .Values.postgres.credentials.usernameFromSecret }}
    valueFrom:
      secretKeyRef:
        name: {{ .Values.postgres.credentials.usernameFromSecret.name }}
        key: {{ .Values.postgres.credentials.usernameFromSecret.key }}
  {{- else }}
    value: {{ .Values.postgres.credentials.username | quote }}
  {{- end }}
  - name: POSTGRES_PASSWORD
    {{- if .Values.postgres.credentials.passwordFromSecret }}
    valueFrom:
      secretKeyRef:
        name: {{ .Values.postgres.credentials.passwordFromSecret.name }}
        key: {{ .Values.postgres.credentials.passwordFromSecret.key }}
    {{- else }}
    value: {{ .Values.postgres.credentials.password | quote }}
    {{- end }}
  - name: POSTGRES_HOST
    value: {{ .Values.postgres.credentials.hostname | quote }}
  - name: POSTGRES_DATABASE
    value: {{ .Values.postgres.credentials.database | quote }}
  {{- end }}
  - name: SECRET_JWT_KEY
    value: {{ .Values.configuration.secrets.jwt | quote }}
  - name: SECRET_SESSION_STORE
    value: {{ .Values.configuration.secrets.session | quote }}
{{- end }}
