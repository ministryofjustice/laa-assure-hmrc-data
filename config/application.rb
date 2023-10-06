require_relative "boot"

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

# Custom railties that are not gems can be required here
require_relative '../lib/govuk_component'

module LaaAssureHmrcData
  class Application < Rails::Application
    # Initialize configuration defaults for Rails version.
    config.load_defaults 7.1

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

    # https://edgeguides.rubyonrails.org/active_storage_overview.html#authenticated-controllers
    # TODO: can we just expose the routes we need? is there another way to handle this?
    # we need to use the `rails_blob_path` helper
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
  end
end
