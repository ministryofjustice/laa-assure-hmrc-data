# https://github.com/omniauth/omniauth/wiki/Integration-Testing
#
OmniAuth.configure do |config|
  config.test_mode = true

  # Add custom azure AD mock response
  config.mock_auth[:azure_ad] = OmniAuth::AuthHash.new({
   provider: "azure_ad",
   uid: "fake-uid",
   info:
    {email: "Jim.Bob@example.co.uk",
     first_name: "Jim",
     last_name: "Bob"},
  })
end
