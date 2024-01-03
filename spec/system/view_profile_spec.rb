require "system_helper"

RSpec.describe "view profile" do
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
    click_on "Jim Bob"
    expect(page).to have_css("h1", text: "Jim Bob")
    expect(page).to have_css(".govuk-summary-list__key", text: "First name")
    expect(page).to have_css(".govuk-summary-list__value", text: "Jim")
    expect(page).to have_css(".govuk-summary-list__key", text: "Last name")
    expect(page).to have_css(".govuk-summary-list__value", text: "Bob")
    expect(page).to have_css(".govuk-summary-list__key", text: "Email")
    expect(page).to have_css(".govuk-summary-list__value", text: "jim.bob@example.co.uk")
  end
end
