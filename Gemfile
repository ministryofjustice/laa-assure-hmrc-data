source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

gem "bootsnap", require: false
gem "cssbundling-rails"
gem 'devise'
gem 'dotenv-rails'
gem "govuk-components"
gem "govuk_design_system_formbuilder"
gem "jsbundling-rails"
gem 'omniauth_openid_connect'
gem "omniauth-rails_csrf_protection"
gem "pg", "~> 1.4"
gem "propshaft"
gem "puma", "~> 6.2"
gem "rails", "~> 7.0.4"
gem "sentry-rails"
gem "sentry-ruby"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]
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
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "webdrivers"
end

group :test, :development do
  gem "erb_lint", require: false
  gem 'i18n-tasks'
  gem "overcommit"
  gem "rspec"
  gem "rspec-rails"
end
