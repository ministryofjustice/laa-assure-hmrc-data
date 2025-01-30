source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: ".ruby-version"

gem 'aws-sdk-s3', require: false
gem "bootsnap", require: false
gem "cssbundling-rails"
gem "csv", require: false
gem 'devise'
gem "discard", "~> 1.4"
gem 'dotenv'
gem "govuk-components"
gem "govuk_design_system_formbuilder"
gem "jsbundling-rails"
gem "nesty"
gem "oauth2"
gem 'omniauth_openid_connect'
gem "omniauth-rails_csrf_protection"
gem "pg", "~> 1.5"
gem "propshaft"
gem "puma", "~> 6.6"
gem "rails", "~> 8.0.1"
gem "sentry-rails"
gem "sentry-ruby"
gem "sidekiq"
gem "sidekiq-scheduler"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "erb_lint", require: false
  gem 'factory_bot_rails'
  gem 'i18n-tasks'
  gem "overcommit"
  gem "rspec"
  gem "rspec-rails"
  gem "webmock"
end

group :development do
  gem "prettier_print", require: false
  gem "rubocop-govuk", require: false
  gem "rubocop-performance", require: false
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem 'rails-controller-testing'
  gem 'rspec-html-matchers'
  gem "selenium-webdriver"
  gem "simplecov", require: false
end
