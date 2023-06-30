require "hmrc_interface"

HmrcInterface.configure do |config|
  config.client_id = ENV.fetch("HMRC_INTERFACE_UID", nil)
  config.client_secret = ENV.fetch("HMRC_INTERFACE_SECRET", nil)
  config.host = ENV.fetch("HMRC_INTERFACE_HOST", nil)
  config.scopes = %i[use_case_one use_case_two]
  config.logger = Rails.logger
end
