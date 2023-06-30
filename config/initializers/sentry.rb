require "active_support/parameter_filter"

if ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.enabled_environments = %w[production]

    config.breadcrumbs_logger = [:active_support_logger]

    filter =
      ActiveSupport::ParameterFilter.new(
        Rails.application.config.filter_parameters
      )

    config.before_send =
      lambda do |event, hint|
        if hint[:exception].is_a?(ActiveRecord::ConnectionNotEstablished)
          event.fingerprint = ["database-unavailable"]
        end

        filter.filter(event.to_hash)
      end
  end
end
