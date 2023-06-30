require "system_helper"

RSpec.describe "view profile", type: :system do
  let(:user) do
    User.create!(
      email: "Jim.Bob@example.co.uk",
      first_name: "Jim",
      last_name: "Bob",
      auth_provider: "azure_ad"
    )
  end

  before { sign_in user }

  it "takes user to home page" do
    visit "/"
    click_link "Jim Bob"
    expect(page).to have_selector("h1", text: "Jim Bob")
    expect(page).to have_selector(
      ".govuk-summary-list__key",
      text: "First name"
    )
    expect(page).to have_selector(".govuk-summary-list__value", text: "Jim")
    expect(page).to have_selector(".govuk-summary-list__key", text: "Last name")
    expect(page).to have_selector(".govuk-summary-list__value", text: "Bob")
    expect(page).to have_selector(".govuk-summary-list__key", text: "Email")
    expect(page).to have_selector(
      ".govuk-summary-list__value",
      text: "jim.bob@example.co.uk"
    )
  end
end
