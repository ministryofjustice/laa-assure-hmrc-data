{{/* vim: set filetype=mustache: */}}
{{/*
Environment variables for web and worker containers
*/}}
{{- define "assure-hmrc-data.envs" }}
env:
  {{ if .Values.postgresql.enabled }}
  - name: POSTGRES_USER
    value: {{ .Values.postgresql.postgresqlUsername }}
  - name: POSTGRES_PASSWORD
    value: {{ .Values.postgresql.postgresqlPassword }}
  - name: POSTGRES_HOST
    value: {{ printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" }}
  - name: POSTGRES_DATABASE
    value: {{ .Values.postgresql.postgresqlDatabase }}
  {{ else }}
  - name: POSTGRES_USER
    valueFrom:
      secretKeyRef:
        name: rds-postgresql-instance-output
        key: database_username
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: rds-postgresql-instance-output
        key: database_password
  - name: POSTGRES_HOST
    valueFrom:
      secretKeyRef:
        name: rds-postgresql-instance-output
        key: rds_instance_address
  - name: POSTGRES_DATABASE
    valueFrom:
      secretKeyRef:
        name: rds-postgresql-instance-output
        key: database_name
  {{ end }}
  - name: RAILS_ENV
    value: production
  - name: RAILS_SERVE_STATIC_FILES
    value: only-presence-required
  - name: RAILS_LOG_TO_STDOUT
    value: 'true'
  - name: SECRET_KEY_BASE
    valueFrom:
      secretKeyRef:
        name: assure-hmrc-data-application-output
        key: secret_key_base
{{- end }}
