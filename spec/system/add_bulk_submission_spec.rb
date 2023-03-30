require "system_helper"

RSpec.describe "sign in", type: :system do
  context "with unauthorised user" do
    it "redirects user back to landing page" do
      visit "/bulk_submissions/new"
      expect(page).to have_content("Start now")
    end
  end


  context "with an authorised user" do
    before { sign_in user }

    let(:user) { create(:user, :with_matching_stubbed_oauth_details) }

    it "user can upload and delete a CSV" do
      visit "/bulk_submissions/new"

      expect(page).to have_link("Jim Bob")
      expect(page).to have_link("Sign out")
      expect(page).to have_link("Back")

      expect(page).to have_content("Upload a file")

      within("#uploaded-files-table-container") do
        expect(page).to have_selector(".govuk-body", text: "Files uploaded will appear here")
      end

      attach_file(Rails.root.join("spec/fixtures/files/basic_bulk_submission.csv")) do
        page.find("#bulk-submission-form-original-file-field").click
      end

      click_button "Upload"

      within("#uploaded-files-table-container") do
        expect(page).to have_selector(".govuk-table__cell", text: "basic_bulk_submission.csv")
        expect(page).to have_selector(".govuk-table__cell .govuk-tag", text: "UPLOADED")
        expect(page).to have_button("Delete")

        click_button "Delete"
        expect(page).to have_selector(".govuk-body", text: "Files uploaded will appear here")
      end
    end
  end
end
