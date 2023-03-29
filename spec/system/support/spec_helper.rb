# RSpec system test configuration only.
#
# For javascript reliant system tests
# you can use js: true
# e.g.
# it "does something", js: true do
#   visit "/"
#   expect(page).to have...
# end
#
# For non-headless chrome mode you can set BROWSER envvar
# e.g.
# $ BROWSER=true rspec spec/system
#
RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers

  config.before(:each, type: :system) do
    if ENV["BROWSER"].present?
      driven_by :chrome
    else
      driven_by :rack_test
    end
  end

  config.before(:each, type: :system, js: true) do
    if ENV["BROWSER"].present?
      driven_by :chrome
    else
      driven_by :headless_chrome
    end
  end
end
