source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

gem 'aws-sdk-s3', require: false
gem "bootsnap", require: false
gem "cssbundling-rails"
gem 'devise'
gem "discard", "~> 1.3"
gem 'dotenv-rails'
gem "govuk-components"
gem "govuk_design_system_formbuilder"
gem "jsbundling-rails"
gem "nesty"
gem "oauth2"
gem 'omniauth_openid_connect'
gem "omniauth-rails_csrf_protection"
gem "pg", "~> 1.5"
gem "propshaft"
gem "puma", "~> 6.4"
gem "rails", "~> 7.1.1"
gem "sentry-rails"
gem "sentry-ruby"
gem "sidekiq"
gem "sidekiq-scheduler"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
end

group :development do
  gem "prettier_print", require: false
  gem "rubocop-govuk", require: false
  gem "rubocop-performance", require: false
  gem "syntax_tree", require: false
  gem "syntax_tree-haml", require: false
  gem "syntax_tree-rbs", require: false
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

group :test, :development do
  gem "erb_lint", require: false
  gem 'i18n-tasks'
  gem "overcommit"
  gem "rspec"
  gem "rspec-rails"
  gem "webmock"
end
