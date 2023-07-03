require "system_helper"

RSpec.describe "sign in" do
  context "with unauthorised user" do
    it "redirects user back to landing page" do
      visit "/bulk_submission_forms/new"
      expect(page).to have_content("Start now")
    end
  end

  context "with an authorised user" do
    before { sign_in user }

    let(:user) { create(:user, :with_matching_stubbed_oauth_details) }

    it "user sees upload fields, not dropzone fields" do
      visit "/bulk_submission_forms/new"

      expect(page).to have_field("uploaded_file")
      expect(page).to have_button("Upload")

      expect(page).to have_selector("#dropzone-form-group.hidden")
      expect(page).not_to have_selector(".dz-clickable", visible: :all)
      expect(page).not_to have_selector(".dz-hidden-input", visible: :all)
    end

    it "user can upload and delete a CSV from a bulk submission" do
      visit "/bulk_submission_forms/new"
      expect(page).to have_content("Upload a file")

      within("#uploaded-files-table-container") do
        expect(page).to have_selector(".govuk-body", text: "Files uploaded will appear here")
      end

      attach_file('uploaded_file', file_fixture("basic_bulk_submission.csv"))
      click_button "Upload"

      within("#uploaded-files-table-container") do
        expect(page)
          .to have_selector(".govuk-table__cell", text: "basic_bulk_submission.csv")
          .and have_selector(".govuk-table__cell .govuk-tag", text: /Uploaded/i)
          .and have_button("Delete")

        click_button "Delete"

        expect(page).to have_selector(".govuk-body", text: "Files uploaded will appear here")
      end
    end

    it "user can upload and update a CSV on a bulk submission" do
      visit "/bulk_submission_forms/new"
      expect(page).to have_content("Upload a file")

      within("#uploaded-files-table-container") do
        expect(page).to have_selector(".govuk-body", text: "Files uploaded will appear here")
      end

      attach_file('uploaded_file', file_fixture("basic_bulk_submission.csv"))
      click_button "Upload"

      within("#uploaded-files-table-container") do
        expect(page).to have_selector(".govuk-table__cell", text: "basic_bulk_submission.csv")
      end

      attach_file('uploaded_file', file_fixture("basic_bulk_submission_copy.csv"))
      click_button "Upload"

      within("#uploaded-files-table-container") do
        expect(page).to have_selector(".govuk-table__cell", text: "basic_bulk_submission_copy.csv")
      end
    end
  end
end
