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
  {{ if .Values.branch_builder.enabled }}
  - name: POSTGRES_DATABASE
    value: {{ .Values.branch_builder.database_name | quote }}
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
  - name: OMNIAUTH_AZURE_CLIENT_ID
    valueFrom:
      secretKeyRef:
        name: assure-hmrc-data-application-output
        key: omniauth_azure_client_id
  - name: OMNIAUTH_AZURE_CLIENT_SECRET
    valueFrom:
      secretKeyRef:
        name: assure-hmrc-data-application-output
        key: omniauth_azure_client_secret
  - name: OMNIAUTH_AZURE_TENANT_ID
    valueFrom:
      secretKeyRef:
        name: assure-hmrc-data-application-output
        key: omniauth_azure_tenant_id
  {{ if .Values.branch_builder.enabled }}
  - name: OMNIAUTH_AZURE_REDIRECT_URI
    value: {{ .Values.branch_builder.omniauth_azure_redirect_uri }}
  {{ else }}
  - name: OMNIAUTH_AZURE_REDIRECT_URI
    value:
  {{ end }}
  - name: AR_ENCRYPTION_PRIMARY_KEY
    valueFrom:
      secretKeyRef:
        name: assure-hmrc-data-application-output
        key: ar_encryption_primary_key
  - name: AR_ENCRYPTION_DETERMINISTIC_KEY
    valueFrom:
      secretKeyRef:
        name: assure-hmrc-data-application-output
        key: ar_encryption_deterministic_key
  - name: AR_ENCRYPTION_KEY_DERIVATION_SALT
    valueFrom:
      secretKeyRef:
        name: assure-hmrc-data-application-output
        key: ar_encryption_key_derivation_salt
{{- end }}
