require "system_helper"

RSpec.describe "View bulk submission index page" do
  context "with unauthorised user" do
    it "redirects user back to landing page" do
      visit "/bulk_submissions"
      expect(page).to have_content("Start now")
    end
  end

  context "with an authorised user" do
    before { sign_in user }

    let(:user) { create(:user, :with_matching_stubbed_oauth_details) }

    it "user can add a bulk_submission then view index/list of bulk submissions" do
      visit "/bulk_submissions"
      expect(page).to have_content("Checked details")

      click_on "Check new details"
      expect(page).to have_content("Upload a file")

      attach_file('uploaded_file', file_fixture("basic_bulk_submission.csv"))
      click_on "Upload"
      click_on "Save and continue"
      expect(page).to have_content("Checked details")

      within(".govuk-table") do
        expect(page)
          .to have_css(".govuk-table__header", text: "Date requested")
          .and have_css(".govuk-table__header", text: "Expiry date")
          .and have_css(".govuk-table__header", text: "File name")
          .and have_css(".govuk-table__header", text: "Status")
          .and have_css(".govuk-table__header", text: "Action")

        expect(page)
          .to have_css(".govuk-table__cell", text: Date.current.strftime("%d %b %Y"))
          .and have_css(".govuk-table__cell", text: "basic_bulk_submission.csv")
          .and have_css(".govuk-table__cell .govuk-tag.govuk-tag--yellow", text: /Pending/i)
          .and have_css(".govuk-table__cell", text: "Cancel")
      end
    end

    context "with an existing pending bulk_submission" do
      before do
        create(:bulk_submission, :with_original_file, :pending)
      end

      it "user can view them" do
        visit "/bulk_submissions"

        within(".govuk-table") do
          expect(page)
            .to have_css(".govuk-table__cell", text: Date.current.strftime("%d %b %Y"))
            .and have_css(".govuk-table__cell", text: "basic_bulk_submission.csv")
            .and have_css(".govuk-table__cell .govuk-tag.govuk-tag--yellow", text: /Pending/i)
            .and have_css(".govuk-table__cell", text: "Cancel")

          expect(page).to have_css(".govuk-table__body tr")
          click_on("basic_bulk_submission.csv", match: :first)
        end

        expect(page).to have_css(".govuk-heading-xl", text: "About this file")
        expect(page).to have_no_button("cancel")

        click_on("Back")
        expect(page).to have_css(".govuk-heading-xl", text: "Checked details")
      end

      it "user can go to the cancel confirmation page" do
        visit "/bulk_submissions"

        within(".govuk-table") do
          expect(page)
            .to have_css(".govuk-table__cell", text: Date.current.strftime("%d %b %Y"))
            .and have_css(".govuk-table__cell", text: "basic_bulk_submission.csv")
            .and have_css(".govuk-table__cell .govuk-tag.govuk-tag--yellow", text: /Pending/i)
            .and have_css(".govuk-table__cell", text: "Cancel")

          expect(page).to have_css(".govuk-table__body tr")
          click_on("Cancel", match: :one)
        end

        expect(page).to have_css(".govuk-heading-xl", text: "Are you sure you want to cancel this check?")
        expect(page).to have_button("Yes, cancel check on basic_bulk_submission.csv")
      end
    end

    context "with an existing ready bulk_submission" do
      before do
        create(:bulk_submission, :with_original_file, :with_result_file, :ready)
      end

      it "user can view them" do
        visit "/bulk_submissions"

        within(".govuk-table") do
          expect(page)
            .to have_css(".govuk-table__cell", text: Date.current.strftime("%d %b %Y"))
            .and have_css(".govuk-table__cell", text: "basic_bulk_submission.csv")
            .and have_link("basic_bulk_submission.csv")
            .and have_css(".govuk-table__cell .govuk-tag.govuk-tag--green", text: /Ready/i)
            .and have_css(".govuk-table__cell", text: "Remove")

          expect(page).to have_css(".govuk-table__body tr")
          click_on("basic_bulk_submission.csv", match: :first)
        end

        expect(page).to have_css(".govuk-heading-xl", text: "About this file")
        expect(page).to have_no_button("basic_bulk_submission")

        click_on("Back")
        expect(page).to have_css(".govuk-heading-xl", text: "Checked details")
      end

      it "user can go to the remove confirmation page" do
        visit "/bulk_submissions"

        within(".govuk-table") do
          expect(page)
            .to have_css(".govuk-table__cell", text: Date.current.strftime("%d %b %Y"))
            .and have_css(".govuk-table__cell", text: "basic_bulk_submission.csv")
            .and have_link("basic_bulk_submission.csv")
            .and have_css(".govuk-table__cell .govuk-tag.govuk-tag--green", text: /Ready/i)
            .and have_css(".govuk-table__cell", text: "Download results file for basic_bulk_submission.csv")
            .and have_css(".govuk-table__cell", text: "Remove")

          expect(page).to have_no_css(".govuk-table__cell", text: "Cancel")

          expect(page).to have_css(".govuk-table__body tr")
          click_on("Remove", match: :one)
        end

        expect(page).to have_css(".govuk-heading-xl", text: "Are you sure you want to remove this file?")
        expect(page).to have_button("Yes, remove file basic_bulk_submission.csv")
      end

      it "user can download them", :js do
        visit "/bulk_submissions"

        within(".govuk-table") do
            expect(page)
            .to have_css(".govuk-table__cell", text: Date.current.strftime("%d %b %Y"))
            .and have_css(".govuk-table__cell", text: "basic_bulk_submission.csv")
            .and have_link("basic_bulk_submission.csv")
            .and have_css(".govuk-table__cell .govuk-tag.govuk-tag--green", text: /Ready/i)
            .and have_css(".govuk-table__cell", text: "Download results file for basic_bulk_submission.csv")
            .and have_css(".govuk-table__cell", text: "Remove")

          expect(page).to have_no_css(".govuk-table__cell", text: "Cancel")

          expect(page).to have_css(".govuk-table__body tr")
          click_on("Download results file for basic_bulk_submission.csv", match: :one)

          wait_for_download
          expect(downloads.length).to eq(1)
          expect(download).to match(/basic_bulk_submission-result.csv/)
        end
      end
    end

    context "with an existing processing bulk_submission" do
      before do
        create(:bulk_submission, :with_original_file, :processing)
      end

      it "user can NOT remove, cancel or download them" do
        visit "/bulk_submissions"

        within(".govuk-table") do
          expect(page)
            .to have_css(".govuk-table__cell", text: Date.current.strftime("%d %b %Y"))
            .and have_css(".govuk-table__cell", text: "basic_bulk_submission.csv")
            .and have_link("basic_bulk_submission.csv")
            .and have_css(".govuk-table__cell", text: /Processing/i)

          expect(page).to have_no_css(".govuk-table__cell", text: "Download")
          expect(page).to have_no_css(".govuk-table__cell", text: "Remove")
          expect(page).to have_no_css(".govuk-table__cell", text: "Cancel")
        end
      end
    end

    context "with an existing exhausted bulk_submission" do
      before do
        create(:bulk_submission, :with_original_file, :exhausted)
      end

      it "user can go to the remove confirmation page" do
        visit "/bulk_submissions"

        within(".govuk-table") do
          expect(page)
            .to have_css(".govuk-table__cell", text: Date.current.strftime("%d %b %Y"))
            .and have_css(".govuk-table__cell", text: "basic_bulk_submission.csv")
            .and have_link("basic_bulk_submission.csv")
            .and have_css(".govuk-table__cell .govuk-tag.govuk-tag--red", text: /Exhausted/i)
            .and have_css(".govuk-table__cell", text: "Remove")

          expect(page).to have_no_css(".govuk-table__cell", text: "Cancel")
          expect(page).to have_no_css(".govuk-table__cell", text: "Download")

          expect(page).to have_css(".govuk-table__body tr")
          click_on("Remove", match: :one)
        end

        expect(page).to have_css(".govuk-heading-xl", text: "Are you sure you want to remove this file?")
        expect(page).to have_button("Yes, remove file basic_bulk_submission.csv")
      end
    end
  end
end
