# frozen_string_literal: true

require "omniauth"

# Constants or methods to stub omniauth auth hash
# responses from providers.
class MockAzureAdAuthHash
  JIM_BOB =
    OmniAuth::AuthHash.new(
      {
        provider: "azure_ad",
        uid: "jim-bob-fake-uid",
        info: {
          email: "Jim.Bob@example.co.uk",
          first_name: "Jim",
          last_name: "Bob"
        }
      }
    )
end
