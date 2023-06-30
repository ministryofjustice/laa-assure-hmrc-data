Sidekiq.configure_server { |config| config.logger = Rails.logger }

Sidekiq.configure_client { |config| config.logger = Rails.logger }
