require "system_helper"

RSpec.describe "sign in", type: :system, js: true do
  context "with unauthorised user" do
    it "redirects user back to landing page" do
      visit "/bulk_submission_forms/new"
      expect(page).to have_content("Start now")
    end
  end

  context "with an authorised user" do
    before { sign_in user }

    let(:user) { create(:user, :with_matching_stubbed_oauth_details) }

    context "with an acceptable file" do
      it "user sees dropzone fields, not upload fields" do
        visit "/bulk_submission_forms/new"

        expect(page).not_to have_field("uploaded_file")
        expect(page).not_to have_button("Upload")

        expect(page)
          .to have_selector("#dropzone-form-group", visible: :visible)
          .and have_selector(".dz-clickable", visible: :visible)
          .and have_selector(".dz-hidden-input", visible: :hidden)
      end

      it "user can upload and delete a CSV from a bulk submission" do
        visit "/bulk_submission_forms/new"
        expect(page).to have_content("Upload a file")
        expect(page).to have_selector(".govuk-hint", text: "The maximum file size is 1MB. Files must be a CSV.")

        within(".dropzone") do
          expect(page).to have_selector(".govuk-body", text: "Drag and drop files here or")
          expect(page).to have_button("dz-upload-button", text: "Choose files")
        end

        within("#uploaded-files-table-container") do
          expect(page).to have_selector(".govuk-body", text: "Files uploaded will appear here")
        end

        # this emulates a drop of a file on the dropzone
        find(".dz-clickable").drop(file_fixture("basic_bulk_submission.csv"))

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
        expect(page).to have_selector(".govuk-hint", text: "The maximum file size is 1MB. Files must be a CSV.")

        within(".dropzone") do
          expect(page).to have_selector(".govuk-body", text: "Drag and drop files here or")
          expect(page).to have_button("dz-upload-button", text: "Choose files")
        end

        within("#uploaded-files-table-container") do
          expect(page).to have_selector(".govuk-body", text: "Files uploaded will appear here")
        end

        # this emulates a drop of a file on the dropzone
        find(".dz-clickable").drop(file_fixture("basic_bulk_submission.csv"))

        within("#uploaded-files-table-container") do
          expect(page).to have_selector(".govuk-table__cell", text: "basic_bulk_submission.csv")
        end

        # Double-check we have been redirected to the edit page at this point.
        # Note that the previous check will have waited until unsuccessful,
        # thus waiting on the redirect to complete.
        expect(page).to have_current_path(edit_bulk_submission_form_path(BulkSubmission.last.id))

        # this emulates a click on dropzone and select of file
        attach_file(file_fixture("basic_bulk_submission_copy.csv")) do
          find(".dz-clickable").click
        end

        within("#uploaded-files-table-container") do
          expect(page).to have_selector(".govuk-table__cell", text: "basic_bulk_submission_copy.csv")
        end
      end
    end

    context "with unacceptable files on the new page" do
      it "renders summary and field level errors" do
        visit "/bulk_submission_forms/new"
        expect(page).to have_content("Upload a file")

        click_button "Save and continue"
        expect(page)
          .to have_selector(".govuk-error-summary__title", text: "There is a problem")
          .and have_selector(".govuk-error-summary__body", text: "You must select a file to upload")
          .and have_selector(".govuk-error-message", text: "You must select a file to upload")

        find(".dz-clickable").drop(file_fixture("empty.csv"))
        expect(page)
          .to have_selector(".govuk-error-summary__title", text: "There is a problem")
          .and have_selector(".govuk-error-summary__body", text: "empty.csv is empty")
          .and have_selector(".govuk-error-message", text: "empty.csv is empty")

        find(".dz-clickable").drop(file_fixture("invalid_content_type_png_as_csv.csv"))
        expect(page)
          .to have_selector(".govuk-error-summary__body", text: "invalid_content_type_png_as_csv.csv must be a CSV")
          .and have_selector(".govuk-error-message", text: "invalid_content_type_png_as_csv.csv must be a CSV")

        find(".dz-clickable").drop(file_fixture("over_1mb.csv"))
        expect(page)
          .to have_selector(".govuk-error-summary__body", text: "over_1mb.csv is more than 1MB")
          .and have_selector(".govuk-error-message", text: "over_1mb.csv is more than 1MB")

        find(".dz-clickable").drop(file_fixture("empty.png"))
        expect(page)
          .to have_selector(".govuk-error-summary__body", text: "empty.png must be a CSV")
          .and have_selector(".govuk-error-summary__body", text: "empty.png is empty")
          .and have_selector(".govuk-error-message", text: "empty.png must be a CSV")
          .and have_selector(".govuk-error-message", text: "empty.png is empty")
      end
    end

    context "with unacceptable files on the edit page" do
      let(:bulk_submission) do
        create(:bulk_submission,
               :with_original_file,
               original_file_fixture_name: "basic_bulk_submission.csv",
               original_file_fixture_content_type: "text/csv",)
      end

      it "renders summary and field level errors" do
        visit edit_bulk_submission_form_path(bulk_submission.id)

        expect(page).to have_current_path(edit_bulk_submission_form_path(bulk_submission.id))
        expect(page).to have_content("Upload a file")

        within("#uploaded-files-table-container") do
          expect(page)
            .to have_selector(".govuk-table__cell", text: "basic_bulk_submission.csv")
            .and have_selector(".govuk-table__cell .govuk-tag", text: /Uploaded/i)
            .and have_button("Delete")
        end

        find(".dz-clickable").drop(file_fixture("empty.csv"))
        expect(page)
          .to have_selector(".govuk-error-summary__title", text: "There is a problem")
          .and have_selector(".govuk-error-summary__body", text: "empty.csv is empty")
          .and have_selector(".govuk-error-message", text: "empty.csv is empty")

        find(".dz-clickable").drop(file_fixture("invalid_content_type_png_as_csv.csv"))
        expect(page)
          .to have_selector(".govuk-error-summary__body", text: "invalid_content_type_png_as_csv.csv must be a CSV")
          .and have_selector(".govuk-error-message", text: "invalid_content_type_png_as_csv.csv must be a CSV")

        find(".dz-clickable").drop(file_fixture("over_1mb.csv"))
        expect(page)
          .to have_selector(".govuk-error-summary__body", text: "over_1mb.csv is more than 1MB")
          .and have_selector(".govuk-error-message", text: "over_1mb.csv is more than 1MB")

        find(".dz-clickable").drop(file_fixture("empty.png"))
        expect(page)
          .to have_selector(".govuk-error-summary__body", text: "empty.png must be a CSV")
          .and have_selector(".govuk-error-summary__body", text: "empty.png is empty")
          .and have_selector(".govuk-error-message", text: "empty.png must be a CSV")
          .and have_selector(".govuk-error-message", text: "empty.png is empty")
      end
    end
  end
end
