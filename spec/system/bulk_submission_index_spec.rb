require "system_helper"

RSpec.describe "sign in", type: :system do
  context "with unauthorised user" do
    it "redirects user back to landing page" do
      visit "/bulk_submissions"
      expect(page).to have_content("Start now")
    end
  end

  context "with an authorised user" do
    before { sign_in user }

    let(:user) { create(:user, :with_matching_stubbed_oauth_details) }

    it "user can view index/list of bulk submissions and delete them" do
      visit "/bulk_submissions"
      expect(page).to have_content("Checked details")

      click_link "Make a new request"
      expect(page).to have_content("Upload a file")

      attach_file('uploaded_file', file_fixture("basic_bulk_submission.csv"))
      click_button "Upload"
      click_button "Save and continue"
      expect(page).to have_content("Checked details")

      within(".govuk-table") do
        expect(page)
          .to have_selector(".govuk-table__header", text: "Date requested")
          .and have_selector(".govuk-table__header", text: "Expiry date")
          .and have_selector(".govuk-table__header", text: "Status")
          .and have_selector(".govuk-table__header", text: "Action")

        expect(page)
          .to have_selector(".govuk-table__cell", text: Date.current.strftime("%d %b %Y"))
          .and have_selector(".govuk-table__cell", text: /Pending/i)
          .and have_selector(".govuk-table__cell", text: "Remove")

        expect(page).to have_selector(".govuk-table__body tr")
        click_button("Remove", match: :one)
        expect(page).not_to have_selector(".govuk-table__body tr")
      end
    end
  end
end
