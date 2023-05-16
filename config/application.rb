require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LaaAssureHmrcData
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.assets.paths << Rails.root.join(
      "node_modules/govuk-frontend/govuk/assets"
    )

    # Disable active_storage routes as
    #  1. not using and not intending to
    #  2. they are publicly accessible by default
    # https://edgeguides.rubyonrails.org/active_storage_overview.html#authenticated-controllers
    config.active_storage.draw_routes = false

    config.exceptions_app = routes
    config.x.status.build_date = ENV.fetch("APP_BUILD_DATE", "Not Available")
    config.x.status.build_tag = ENV.fetch("APP_BUILD_TAG", "Not Available")
    config.x.status.git_commit = ENV.fetch("APP_GIT_COMMIT", "Not Available")
    config.x.status.app_branch = ENV.fetch("APP_BRANCH", "Not Available")

    # ActiveRecord::Encryption keys generated with `bin/rails db:encryption:init`
    config.active_record.encryption.primary_key = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY", "fake-primary-key")
    config.active_record.encryption.deterministic_key = ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY", "fake-deterministic-key")
    config.active_record.encryption.key_derivation_salt = ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT", "fake-key-derivation-salt")

    config.x.mock_azure = ENV.fetch("MOCK_AZURE", "false")=="true"
    config.x.mock_azure_username = ENV.fetch("MOCK_AZURE_USERNAME", nil)
    config.x.mock_azure_password = ENV.fetch("MOCK_AZURE_PASSWORD", nil)

    config.x.host_env = ENV.fetch("HOST_ENV", nil)

    # TEMP: to allow debug in development and uat while building the request processing aspect of the app
    config.log_level = config.x.host_env == "uat" || Rails.env.development? ? :debug : :info
  end
end
