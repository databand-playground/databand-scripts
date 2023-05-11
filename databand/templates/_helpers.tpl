{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "databand.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 42 chars because some Kubernetes name fields are limited to 63 characters (by the DNS naming spec).
As we added additional characters in templates, 42 characters is maximum for databand helm chart.
We should avoid release name more than 41 characters if we you postgres bitnami helm chart.
We cannot override .Release.Name for subchart.
*/}}
{{- define "databand.fullname" -}}
{{- printf "%s" .Release.Name | trunc 42 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "databand.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "databand.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "databand.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified postgresql name or use the `postgresHost` value if defined.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "databand.postgresql.fullname" -}}
{{- if .Values.postgresql.postgresHost }}
    {{- .Values.postgresql.postgresHost -}}
{{- else }}
    {{- $name := default "postgresql" .Values.postgresql.nameOverride -}}
    {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a random string if the supplied key does not exist
*/}}
{{- define "databand.defaultsecret" -}}
{{- if . -}}
{{- . | b64enc | quote -}}
{{- else -}}
{{- randAlphaNum 10 | b64enc | quote -}}
{{- end -}}
{{- end -}}

{{/*
Create a cmd run commands to execute during dbnd server startup
*/}}
{{- define "databand.db-waiting.cmdrun" -}}
{{- printf "echo 'wait for DB to pass validation...' && dbnd-web db --wait validate --wait-until-pass --timeout-until-pass %d && " (.Values.databand.initdb.wait_timeout | int) -}}
{{- end -}}

{{- define "databand.web.cmdrun.sync_webapp_all" -}}
{{- if .Values.web.statics.sync_webapp_all -}}
{{- print "echo 'wait for sync-webapp...' && dbnd-web command sync-webapp --wait --all && " -}}
{{- else -}}
{{- print "echo 'wait for sync-webapp...' && dbnd-web command sync-webapp --wait && " -}}
{{- end -}}
{{- end -}}

{{- define "databand.web.cmdrun.adduser" -}}
{{ printf  "dbnd-web db user-create -r Admin -u $DATABAND__CLIENT_ADMIN__USERNAME -e %s_admin@databand.ai -f %s -l admin -p $DATABAND__CLIENT_ADMIN__PASSWORD --skip-existing && " .Values.web.env .Values.web.env }}
{{- end -}}

{{- define "databand.cmdrun" -}}
{{- include "databand.db-waiting.cmdrun" . -}}
echo "executing {{ .cmd }}..." &&
{{- if .Values.databand.newrelic.enabled -}}
{{ print " newrelic-admin run-program" }}
{{- end -}}
{{ .cmd }}
{{- end -}}

{{- define "databand.web.cmdrun" -}}
{{- include "databand.db-waiting.cmdrun" . -}}
{{- include "databand.web.cmdrun.sync_webapp_all" . -}}
{{- if .Values.global.onepassword.enabled -}}
{{- include "databand.web.cmdrun.adduser" . -}}
{{- end -}}
echo "executing dbnd-web webserver..." &&
{{- if .Values.databand.newrelic.enabled -}}
{{ print " newrelic-admin run-program" }}
{{- end -}}
{{ print " dbnd-web webserver --port 8090 --pid /var/run/dbnd/dbnd-webserver.pid" }}
{{- end -}}

{{/*
Create a set of environment variables to be mounted in web, scheduler, and worker pods.
For the database passwords, we actually use the secretes created by the postgres.
Note that the environment variables themselves are determined by the packer/docker-databand image.
See script/entrypoint.sh in that repo for more info.
The key names for postgres is fixed, which is consistent with the subcharts.
*/}}
{{- define "databand.mapenvsecrets" }}
  {{- if and .Values.databand.smtp.enabled (not .Values.global.onepassword.enabled) }}
  - name: DBND__ALERT__SMTP_EMAIL_FROM
    valueFrom:
      secretKeyRef:
        name: {{ printf "%s-%s" .Release.Name "smtp" }}
        key: {{ default "smtp_email_from" }}
  - name: DBND__ALERT__SMTP_HOSTNAME
    valueFrom:
      secretKeyRef:
        name: {{ printf "%s-%s" .Release.Name "smtp" }}
        key: {{ default "smtp_hostname" }}
  - name: DBND__ALERT__SMTP_APIKEY_OR_USERNAME
    valueFrom:
      secretKeyRef:
        name: {{ printf "%s-%s" .Release.Name "smtp" }}
        key: {{ default "smtp_apikey_or_username" }}
  - name: DBND__ALERT__SMTP_TOKEN_OR_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ printf "%s-%s" .Release.Name "smtp" }}
        key: {{ default "smtp_token_or_password" }}
  {{- else if .Values.global.onepassword.enabled }}
  - name: DBND__ALERT__SMTP_EMAIL_FROM
    valueFrom:
      secretKeyRef:
        name: onepassword-env
        key: DBND__ALERT__SMTP_EMAIL_FROM
  - name: DBND__ALERT__SMTP_HOSTNAME
    valueFrom:
      secretKeyRef:
        name: onepassword-env
        key: DBND__ALERT__SMTP_HOSTNAME
  - name: DBND__ALERT__SMTP_APIKEY_OR_USERNAME
    valueFrom:
      secretKeyRef:
        name: onepassword-env
        key: DBND__ALERT__SMTP_APIKEY_OR_USERNAME
  - name: DBND__ALERT__SMTP_TOKEN_OR_PASSWORD
    valueFrom:
      secretKeyRef:
        name: onepassword-env
        key: DBND__ALERT__SMTP_TOKEN_OR_PASSWORD
  {{- end }}
  {{- if and .Values.databand.newrelic.enabled (not .Values.global.onepassword.enabled) }}
  - name: NEW_RELIC_LICENSE_KEY
    valueFrom:
      secretKeyRef:
        name: {{ printf "%s-%s" .Release.Name "newrelic" }}
        key: {{ default "license_key" }}
  {{- else if .Values.global.onepassword.enabled }}
  - name: NEW_RELIC_LICENSE_KEY
    valueFrom:
      secretKeyRef:
        name: onepassword-env
        key: NEW_RELIC_LICENSE_KEY
  {{- end }}
  {{- if and .Values.global.databand.sentry.enabled (not .Values.global.onepassword.enabled) }}
  - name: DBND__WEBSERVER__SENTRY_URL
    valueFrom:
      secretKeyRef:
        name: {{ printf "%s-%s" .Release.Name "sentry" }}
        key: {{ default "url" }}
  {{- else if and .Values.global.databand.sentry.enabled .Values.global.onepassword.enabled }}
  - name: DBND__WEBSERVER__SENTRY_URL
    valueFrom:
      secretKeyRef:
        name: onepassword-env
        key: PUBLIC_SENTRY_URL
  {{- end }}
  {{- if .Values.cloudsqlinstance.enabled }}
  - name: CLOUDSQL_PASSWORD
    valueFrom:
      secretKeyRef:
        name: cloudsqlpostgresql-conn
        key: password
  - name: CLOUDSQL_HOST
    valueFrom:
      secretKeyRef:
        name: cloudsqlpostgresql-conn
        key: endpoint
  {{- else if and .Values.sql_alchemy_conn.existingSecret.name .Values.sql_alchemy_conn.existingSecret.secretKeys.userPasswordKey }}
  - name: DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ .Values.sql_alchemy_conn.existingSecret.name }}
        key: {{ .Values.sql_alchemy_conn.existingSecret.secretKeys.userPasswordKey }}
  {{- end }}
  {{- if .Values.cloudmemorystore.enabled }}
  - name: REDIS_HOST
    valueFrom:
      secretKeyRef:
        name: cloudmemorystore-conn
        key: endpoint
  - name: REDIS_PORT
    valueFrom:
      secretKeyRef:
        name: cloudmemorystore-conn
        key: port
  - name: REDIS_PASSWORD
    valueFrom:
      secretKeyRef:
        name: cloudmemorystore-conn
        key: password
  {{- else if and .Values.inmemorystore.existingSecret.name .Values.inmemorystore.existingSecret.secretKeys.passwordKey }}
  - name: REDIS_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ .Values.inmemorystore.existingSecret.name }}
        key: {{ .Values.inmemorystore.existingSecret.secretKeys.passwordKey }}
  {{- end }}
  {{- if .Values.global.onepassword.enabled }}
  - name: DBND__DEFAULT_USER__USERNAME
    valueFrom:
      secretKeyRef:
        name: databand-internal-secrets
        key: username
  - name: DBND__DEFAULT_USER__PASSWORD
    valueFrom:
      secretKeyRef:
        name: databand-internal-secrets
        key: password
  - name: DBND__WEBSERVER__SECRET_KEY
    valueFrom:
      secretKeyRef:
        name: databand-internal-secrets
        key: DBND__WEBSERVER__SECRET_KEY
  - name: DATABAND__CLIENT_ADMIN__USERNAME
    valueFrom:
      secretKeyRef:
        name: databand-internal-secrets
        key: DATABAND__CLIENT_ADMIN__USERNAME
  - name: DATABAND__CLIENT_ADMIN__PASSWORD
    valueFrom:
      secretKeyRef:
        name: databand-internal-secrets
        key: DATABAND__CLIENT_ADMIN__PASSWORD
  {{ if contains "github" .Values.web.ab_auth.oauth2_providers }}
  - name: DBND__AB_AUTH__GITHUB_KEY
    valueFrom:
      secretKeyRef:
        name: databand-internal-secrets
        key: DBND__AB_AUTH__GITHUB_KEY
  - name: DBND__AB_AUTH__GITHUB_SECRET
    valueFrom:
      secretKeyRef:
        name: databand-internal-secrets
        key: DBND__AB_AUTH__GITHUB_SECRET
  {{ end }}
  {{ if contains "gitlab" .Values.web.ab_auth.oauth2_providers }}
  - name: DBND__AB_AUTH__GITLAB_KEY
    valueFrom:
      secretKeyRef:
        name: databand-internal-secrets
        key: DBND__AB_AUTH__GITLAB_KEY
  - name: DBND__AB_AUTH__GITLAB_SECRET
    valueFrom:
      secretKeyRef:
        name: databand-internal-secrets
        key: DBND__AB_AUTH__GITLAB_SECRET
  {{ end }}
  {{ if contains "okta" .Values.web.ab_auth.oauth2_providers }}
  - name: DBND__AB_AUTH__OKTA_KEY
    valueFrom:
      secretKeyRef:
        name: databand-internal-secrets
        key: DBND__AB_AUTH__OKTA_KEY
  - name: DBND__AB_AUTH__OKTA_SECRET
    valueFrom:
      secretKeyRef:
        name: databand-internal-secrets
        key: DBND__AB_AUTH__OKTA_SECRET
  - name: DBND__AB_AUTH__OKTA_BASE_URL
    valueFrom:
      secretKeyRef:
        name: databand-internal-secrets
        key: DBND__AB_AUTH__OKTA_BASE_URL
  {{ end }}
  {{- end }}
  {{- if .Values.databand.extraEnv }}
{{ toYaml .Values.databand.extraEnv | indent 2 }}
  {{- end }}
{{- end }}

{{- define "imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.global.databand.imageCredentials.registry (printf "%s:%s" .Values.global.databand.imageCredentials.username .Values.global.databand.imageCredentials.password | b64enc) | b64enc }}
{{- end }}


{{/*
prometheus-postgres-exporter configuration
*/}}
{{- define "prometheus-postgres-exporter-sql-connection" -}}
{{- if eq .Values.postgresql.enabled true -}}
postgresql://{{ .Values.postgresql.auth.username }}:{{ .Values.postgresql.auth.password }}@{{ template "databand.fullname" . }}-postgresql:{{ .Values.postgresql.primary.service.ports.postgresql }}/{{ .Values.postgresql.auth.database }}?sslmode=disable
{{- else -}}
postgresql://{{ .Values.sql_alchemy_conn.username }}:{{ .Values.sql_alchemy_conn.password }}@{{ .Values.sql_alchemy_conn.host  }}:{{ .Values.sql_alchemy_conn.port }}/{{ .Values.sql_alchemy_conn.dbname  }}?sslmode=disable
{{- end -}}
{{- end -}}

{{- define "prometheus-postgres-exporter.labels" -}}
app.kubernetes.io/name: {{ include "prometheus-postgres-exporter.name" . }}
component: prometheus-postgres-exporter
{{- end }}

{{/*
external url (for blackbox-exporter ...)
*/}}
{{- define "databand.external_url" -}}
{{- if .Values.ingress.external.enabled -}}
{{- .Values.ingress.external.web.host }}
{{- else if  .Values.ingress.enabled -}}
{{- .Values.ingress.web.host }}
{{- end -}}
{{- end -}}

{{/*
Files labels
*/}}
{{- define "files.path" -}}
{{- printf "%s" "files/"  -}}
{{- end -}}

{{- define "alertmanager.config_path" -}}
{{- printf "%s%s/" (include "files.path" . ) "alertmanager" -}}
{{- end -}}

{{- define "postgres-exporter.config_path" -}}
{{- printf "%s%s/" (include "files.path" . ) "postgres-exporter" -}}
{{- end -}}

{{/*
Get KubeVersion removing pre-release information.
*/}}
{{- define "databand.kubeVersion" -}}
  {{- default .Capabilities.KubeVersion.Version (regexFind "v[0-9]+\\.[0-9]+\\.[0-9]+" .Capabilities.KubeVersion.Version) -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "ingress.apiVersion" -}}
  {{- if and (.Capabilities.APIVersions.Has "networking.k8s.io/v1") (semverCompare ">= 1.19.x" (include "databand.kubeVersion" .)) -}}
      {{- print "networking.k8s.io/v1" -}}
  {{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" -}}
    {{- print "networking.k8s.io/v1beta1" -}}
  {{- else -}}
    {{- print "extensions/v1beta1" -}}
  {{- end -}}
{{- end -}}

{{/*
Return if ingress is stable.
*/}}
{{- define "ingress.isStable" -}}
  {{- eq (include "ingress.apiVersion" .) "networking.k8s.io/v1" -}}
{{- end -}}

{{/*
Return if ingress supports ingressClassName.
*/}}
{{- define "ingress.supportsIngressClassName" -}}
  {{- or (eq (include "ingress.isStable" .) "true") (and (eq (include "ingress.apiVersion" .) "networking.k8s.io/v1beta1") (semverCompare ">= 1.18.x" (include "databand.kubeVersion" .))) -}}
{{- end -}}
{{/*
Return if ingress supports pathType.
*/}}
{{- define "ingress.supportsPathType" -}}
  {{- or (eq (include "ingress.isStable" .) "true") (and (eq (include "ingress.apiVersion" .) "networking.k8s.io/v1beta1") (semverCompare ">= 1.18.x" (include "databand.kubeVersion" .))) -}}
{{- end -}}

{{/*
Calculate redis url
*/}}
{{- define "redis.url" -}}
{{- if eq .Values.redis.enabled true -}}
{{- if .Values.redis.fullnameOverride -}}
redis://:{{ .Values.redis.auth.password }}@{{ .Values.redis.fullnameOverride }}-master:{{ .Values.redis.master.containerPorts.redis }}/0
{{- else -}}
redis://:{{ .Values.redis.auth.password }}@{{ template "databand.fullname" . }}-redis-master:{{ .Values.redis.master.containerPorts.redis }}/0
{{- end -}}
{{- else if eq .Values.cloudmemorystore.enabled true -}}
redis://:$REDIS_PASSWORD@$REDIS_HOST:$REDIS_PORT/0
{{- else if and .Values.inmemorystore.existingSecret.name .Values.inmemorystore.existingSecret.secretKeys.passwordKey -}}
redis://:$REDIS_PASSWORD@{{ .Values.inmemorystore.host }}:{{ .Values.inmemorystore.port }}/0
{{- else -}}
redis://:{{ .Values.inmemorystore.password }}@{{ .Values.inmemorystore.host }}:{{ .Values.inmemorystore.port }}/0
{{- end -}}
{{- end -}}
