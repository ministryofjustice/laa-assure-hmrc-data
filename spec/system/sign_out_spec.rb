require "system_helper"

RSpec.describe "sign out", type: :system do
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
    click_link "Sign out"
    expect(page).to have_button("Start now")
  end
end
