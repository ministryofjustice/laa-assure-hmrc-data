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
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:azure_ad]
  end
end

# Stub omniauth failure and reset back to success afterward.
# Also, swallow stdout message from devise
# nameley: "ERROR -- omniauth: (azure_ad) Authentication failure! invalid_credentials encountered"
RSpec.configure do |config|
  config.around(:each, omniauth_failure: true) do |example|
    mock_azure_ad_invalid_credentials do
      silence_stdout do
        example.run
      end
    end
  end
end

def mock_azure_ad_invalid_credentials
  OmniAuth.config.mock_auth[:azure_ad] = :invalid_credentials
  yield
ensure
  OmniAuth.config.mock_auth[:azure_ad] = MockAzureAdAuthHash::JIM_BOB
end

def silence_stdout
  original_stdout = $stderr.dup
  $stdout.reopen("/dev/null", "w")
  yield
ensure
  $stdout.reopen(original_stdout)
end
