# https://github.com/omniauth/omniauth/wiki/Integration-Testing
#

# Stubs auth requests with the mock auth hash
OmniAuth.configure do |config|
  config.test_mode = true
  config.mock_auth[:azure_ad] = MockAzureAdAuthHash::JIM_BOB
end

# Allows use of the devise integration-testing `sign_in` helper
# with the stubbed user.
RSpec.configure do |config|
  config.before(:each, type: :system) do
    Rails.application.env_config["devise.mapping"] = Devise.mappings[:user] # If using Devise
    Rails.application.env_config["omniauth.auth"] = MockAzureAdAuthHash::JIM_BOB
  end
end
