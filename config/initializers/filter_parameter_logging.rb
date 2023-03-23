# Be sure to restart your server when you modify this file.

# Configure parameters to be filtered from the log file. Use this to limit dissemination of
# sensitive information. See the ActiveSupport::ParameterFilter documentation for supported
# notations and behaviors.
Rails.application.config.filter_parameters += %i[
  passw
  password
  secret
  token
  _key
  crypt
  salt
  certificate
  otp
  ssn
  oid
  tenant_id
  client_id
  client_secret
  pkce
  uid
  name
  nickname
  phone
  email
  auth_subject_id
  first_name
  last_name
  credentials
  extra
]
