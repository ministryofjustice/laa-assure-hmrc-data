# https://github.com/omniauth/omniauth/wiki/Integration-Testing
#

# Custom azure AD mock response
class MockAzureAdAuthHash
  JIM_BOB = OmniAuth::AuthHash.new({
               provider: "azure_ad",
               uid: "fake-uid",
               info:
                {email: "Jim.Bob@example.co.uk",
                 first_name: "Jim",
                 last_name: "Bob"},
            })
end

OmniAuth.configure do |config|
  config.test_mode = true
  config.mock_auth[:azure_ad] = MockAzureAdAuthHash::JIM_BOB
end

# This config allows use of the devise integration testing `sign_in` helper
# with the stubbed user.
RSpec.configure do |config|
  config.before(:each, type: :system) do
    Rails.application.env_config["devise.mapping"] = Devise.mappings[:user] # If using Devise
    Rails.application.env_config["omniauth.auth"] = MockAzureAdAuthHash::JIM_BOB
  end
end
