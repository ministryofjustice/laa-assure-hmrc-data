{{/* vim: set filetype=mustache: */}}
{{/*
Environment variables for web and worker containers
*/}}
{{- define "assure-hmrc-data.envs" }}
env:
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
  {{ if .Values.branch_builder_database.enabled }}
  - name: POSTGRES_DATABASE
    value: {{ .Values.branch_builder_database.name | quote }}
  {{ else }}
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
  - name: SENTRY_DSN
    valueFrom:
      secretKeyRef:
        name: assure-hmrc-data-application-output
        key: sentry_dsn
{{- end }}
