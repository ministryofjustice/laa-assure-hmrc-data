require "system_helper"

RSpec.describe "sign in", type: :system do
  context "with unauthorised user" do
    it "redirects user back to landing page" do
      visit "/"
      click_button "Start now"
      expect(page).to have_content("Start now")
    end
  end

  context "with an authorised user on first time login" do
    before do
      User.create!(email: "Jim.Bob@example.co.uk", auth_provider: "azure_ad")
    end

    it "takes user to home page" do
      visit "/"
      click_button "Start now"
      expect(page).to have_content("Submissions")
      expect(page).to have_link("Jim Bob")
      expect(page).to have_link("Sign out")
    end
  end

  context "with an authorised user on subsequent logins" do
    before do
      User.create!(auth_subject_uid: "fake-uid")
    end

    it "takes user to home page" do
      visit "/"
      click_button "Start now"
      expect(page).to have_content("Submissions")
    end
  end
end
