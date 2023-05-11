{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "dbnd-dbt-monitor.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dbnd-dbt-monitor.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{- define "dbnd-dbt-monitor.cmdrun" -}}

{{ printf  "dbnd-dbt-monitor" }}
{{- end -}}


{{/*
Create a set of environment variables to be mounted in source-monitor pod.
*/}}
{{- define "dbnd-dbt-monitor.mapenvsecrets" }}
  {{- if not .Values.global.onepassword.enabled }}
  - name: "DBND__CORE__DBND_USER"
    value: {{ .Values.dbnd_username | default "databand" | quote }}
  - name: "DBND__CORE__DBND_PASSWORD"
    value: {{ .Values.dbnd_password | default "databand" | quote }}
  {{- end }}
  {{- if .Values.global.onepassword.enabled }}
  - name: "DBND__CORE__DBND_USER"
    valueFrom:
      secretKeyRef:
        name: databand-internal-secrets
        key: username
  - name: "DBND__CORE__DBND_PASSWORD"
    valueFrom:
      secretKeyRef:
        name: databand-internal-secrets
        key: password
  {{- end }}
  {{- if .Values.databand_access_token }}
  - name: "DBND__CORE__DATABAND_ACCESS_TOKEN"
    valueFrom:
      secretKeyRef:
        key:  databand_access_token
        name: "{{ template "dbnd-dbt-monitor.fullname" . }}"
  {{- end }}

  {{- if and .Values.sentry.enabled (not .Values.global.onepassword.enabled) }}
  - name: SENTRY_DSN
    valueFrom:
      secretKeyRef:
        key: sentry_url
        name: "{{ template "dbnd-dbt-monitor.fullname" . }}"
  {{- else if and .Values.global.databand.sentry.enabled .Values.global.onepassword.enabled }}
  - name: SENTRY_DSN
    valueFrom:
      secretKeyRef:
        name: onepassword-env
        key: PUBLIC_SENTRY_URL
  {{- end }}

{{- end }}
