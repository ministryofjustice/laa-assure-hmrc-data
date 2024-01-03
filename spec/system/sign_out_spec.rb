require "system_helper"

RSpec.describe "sign out" do
  let(:user) do
    User.create!(email: "Jim.Bob@example.co.uk",
                 first_name: "Jim",
                 last_name: "Bob",
                 auth_provider: "azure_ad")
  end

  before do
    sign_in user
  end

  it "takes user to home page" do
    visit "/"
    click_on "Sign out"
    expect(page).to have_button("Start now")
    expect(page).to have_css(".govuk-notification-banner__header", text: "Important")
    expect(page).to have_css(".govuk-notification-banner__content", text: "Signed out successfully")
  end
end
