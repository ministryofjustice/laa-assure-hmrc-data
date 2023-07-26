# Install/update chrome drivers need by selenium

# Afix version for CI and development to latest available working versions (115... has breaking changes)
Webdrivers::Chromedriver.required_version = ENV["CI"] ? "112.0.5615.49" : "114.0.5735.90"

# rubocop:disable Rails/SaveBang
Webdrivers::Chromedriver.update
# rubocop:enable Rails/SaveBang

# Selenium logging
# https://www.selenium.dev/documentation/webdriver/troubleshooting/logging/#ruby
# other args in order of decreasing verbosity\
# :debug, :info, :warn (default), :error, :fatal
Selenium::WebDriver.logger.level = :warn

# We use a Capybara default value here explicitly.
Capybara.default_max_wait_time = 5

# Normalize whitespaces when using `has_text?` and similar matchers,
# i.e., ignore newlines, trailing spaces, etc.
# That makes tests less dependent on slight UI changes.
Capybara.default_normalize_ws = true

# Where to store system tests artifacts (e.g. screenshots, downloaded files, etc.).
# It could be useful to be able to configure this path from the outside (e.g., on CI).
Capybara.save_path = ENV.fetch("CAPYBARA_ARTIFACTS", "./tmp/capybara")

# Register drivers with options
Capybara.register_driver :headless_chrome do |app|
  args = %w[start-maximized headless disable-gpu no-sandbox disable-site-isolation-trials]
  options = Selenium::WebDriver::Chrome::Options.new(args:)

  options.add_preference(:download, prompt_for_download: false, default_directory: DownloadHelper::PATH.to_s)
  options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    clear_local_storage: true,
    clear_session_storage: true,
    options:,
  )
end

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new(args: %w[start-maximized disable-gpu no-sandbox])

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    clear_local_storage: true,
    clear_session_storage: true,
    options:)
end
