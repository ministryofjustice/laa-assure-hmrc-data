require 'system_helper'

# Request specs do not excercise JS, only the
# non-JS controller actions
#
RSpec.describe BulkSubmissionFormsController, type: :request do
  before { sign_in user }

  let(:user) { create(:user) }

  describe "GET /new" do
    it "returns http success and renders new" do
      get new_bulk_submission_form_path
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:new)
    end
  end

  describe "POST /create" do
    let(:bulk_submission_form_params) do
     { commit:, uploaded_file: fixture_file_upload('basic_bulk_submission.csv', 'text/csv')}
    end

    context "with valid file added and upload pressed" do
      let(:commit) { "upload" }

      it "redirects to edit" do
        post bulk_submission_forms_path, params: bulk_submission_form_params
        expect(response).to redirect_to(edit_bulk_submission_form_path(assigns[:form].bulk_submission.id))
      end

      it "creates a bulk_submission" do
        expect {
          post bulk_submission_forms_path, params: bulk_submission_form_params
        }.to change(BulkSubmission, :count).by(1)
      end
    end

    context "with valid file added and continue pressed" do
      let(:commit) { "continue" }

      it "redirects to index" do
        post bulk_submission_forms_path, params: bulk_submission_form_params
        expect(response).to redirect_to(bulk_submissions_path)
      end

      it "creates a bulk_submission" do
        expect {
          post bulk_submission_forms_path, params: bulk_submission_form_params
        }.to change(BulkSubmission, :count).by(1)
      end
    end

    context "with no file added and upload button pressed" do
      let(:bulk_submission_form_params) do
       { commit: "upload" }
      end

      it "renders new with error" do
        post bulk_submission_forms_path, params: bulk_submission_form_params
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:new)
        expect(response.body).to include("You must select a file to upload")
      end

      it "does not create bulk_submission" do
        expect {
          post bulk_submission_forms_path, params: bulk_submission_form_params
        }.not_to change(BulkSubmission, :count)
      end
    end

    context "with empty csv added and upload button pressed" do
      let(:bulk_submission_form_params) do
       { commit: "upload", uploaded_file: fixture_file_upload('empty.csv', 'text/csv')}
      end

      it "renders new with error" do
        post bulk_submission_forms_path, params: bulk_submission_form_params
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:new)
        expect(response.body).to include("empty.csv is empty")
      end

      it "does not create bulk_submission" do
        expect {
          post bulk_submission_forms_path, params: bulk_submission_form_params
        }.not_to change(BulkSubmission, :count)
      end
    end

    context "with invalid file type and upload button pressed" do
      let(:bulk_submission_form_params) do
       { commit: "upload", uploaded_file: fixture_file_upload('empty.png', 'image/png')}
      end

      it "renders new with error" do
        post bulk_submission_forms_path, params: bulk_submission_form_params
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:new)
        expect(response.body).to include("empty.png must be a CSV")
      end

      it "does not create bulk_submission" do
        expect {
          post bulk_submission_forms_path, params: bulk_submission_form_params
        }.not_to change(BulkSubmission, :count)
      end
    end

    context "with invalid CHECKED content_type not matching extension and upload button pressed" do
      let(:bulk_submission_form_params) do
       { commit: "upload", uploaded_file: fixture_file_upload('invalid_content_type_png_as_csv.csv')}
      end

      it "renders new with error" do
        post bulk_submission_forms_path, params: bulk_submission_form_params
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:new)
        expect(response.body).to include("invalid_content_type_png_as_csv.csv must be a CSV")
      end

      it "does not create bulk_submission" do
        expect {
          post bulk_submission_forms_path, params: bulk_submission_form_params
        }.not_to change(BulkSubmission, :count)
      end
    end

    context "with invalid DECLARED content_type not matching extension and upload button pressed" do
      let(:bulk_submission_form_params) do
       { commit: "upload", uploaded_file: fixture_file_upload('basic_bulk_submission.csv', 'image/png')}
      end

      it "renders new with error" do
        post bulk_submission_forms_path, params: bulk_submission_form_params
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:new)
        expect(response.body).to include("basic_bulk_submission.csv must be a CSV")
      end

      it "does not create bulk_submission" do
        expect {
          post bulk_submission_forms_path, params: bulk_submission_form_params
        }.not_to change(BulkSubmission, :count)
      end
    end

    context "with file that is too big and upload button pressed" do
      let(:bulk_submission_form_params) do
       { commit: "upload", uploaded_file: fixture_file_upload('one_byte_too_big.csv')}
      end

      it "renders new with error" do
        post bulk_submission_forms_path, params: bulk_submission_form_params
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:new)
        expect(response.body).to include("one_byte_too_big.csv is more than 1MB")
      end

      it "does not create bulk_submission" do
        expect {
          post bulk_submission_forms_path, params: bulk_submission_form_params
        }.not_to change(BulkSubmission, :count)
      end
    end
  end

  describe "GET /edit" do
    let(:bulk_submission) do
      BulkSubmission.create!(
        user_id: user.id,
        original_file: fixture_file_upload('basic_bulk_submission.csv')
      )
    end

    it "returns http success and renders edit form and uploaded files list" do
      get edit_bulk_submission_form_path(bulk_submission.id)

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
      expect(response.body).to include('basic_bulk_submission.csv')
      expect(response.body).to include('Uploaded')
      expect(response.body).to include('Delete')
    end
  end

  describe "PATCH /update" do
    before { bulk_submission }

    let(:bulk_submission_form_params) do
     { commit:, uploaded_file: fixture_file_upload('basic_bulk_submission_copy.csv', 'text/csv')}
    end

    let(:bulk_submission) do
      BulkSubmission.create!(
        user_id: user.id,
        original_file: fixture_file_upload('basic_bulk_submission.csv', 'text/csv')
      )
    end

    context "with replacement file added and upload pressed" do
      let(:commit) { "upload" }

      it "replaces existing original_file with uploaded_file" do
        patch bulk_submission_form_path(bulk_submission.id), params: bulk_submission_form_params

        expect(response).to redirect_to(edit_bulk_submission_form_path(bulk_submission.id))
        follow_redirect!
        expect(response.body).to include('basic_bulk_submission_copy.csv')
        expect(response.body).to include('Uploaded')
        expect(response.body).to include('Delete')
      end

      it "does not create a new bulk_submission" do
        expect {
          patch bulk_submission_form_path(bulk_submission.id), params: bulk_submission_form_params
        }.not_to change(BulkSubmission, :count)
      end

      it "records the attempt to upload a file" do
        expect {
          patch bulk_submission_form_path(bulk_submission.id), params: bulk_submission_form_params
        }.to change(MalwareScanResult, :count).by(1)
      end
    end

    context "without file added and upload pressed" do
      let(:commit) { "upload" }

      let(:bulk_submission_form_params) { { commit: } }

      it "renders edit and displays error" do
        patch bulk_submission_form_path(bulk_submission.id), params: bulk_submission_form_params

        expect(response).to render_template(:edit)
        expect(response.body).to include('You must select a file to upload')
      end
    end

    context "with invalid file added and upload pressed" do
      let(:commit) { "upload" }

      let(:bulk_submission_form_params) { { commit:, uploaded_file: fixture_file_upload('empty.csv') } }

      it "renders edit and displays error" do
        patch bulk_submission_form_path(bulk_submission.id), params: bulk_submission_form_params
        expect(response).to render_template(:edit)
        expect(response.body).to include('empty.csv is empty')
      end
    end

    context "with malware file added and upload pressed", scan_with_clamav: true do
      let(:commit) { "upload" }

      let(:bulk_submission_form_params) { { commit:, uploaded_file: fixture_file_upload('malware.csv') } }

      it "renders edit and displays error" do
        patch bulk_submission_form_path(bulk_submission.id), params: bulk_submission_form_params
        expect(response).to render_template(:edit)
        expect(response.body).to include('malware.csv contains a virus!')
      end

      it "records the attempt to upload a file" do
        expect {
          patch bulk_submission_form_path(bulk_submission.id), params: bulk_submission_form_params
        }.to change(MalwareScanResult, :count).by(1)
      end
    end

    context "with valid file added and continue pressed" do
      let(:commit) { "continue" }

      it "replaces existing original_file with uploaded_file" do
        patch bulk_submission_form_path(bulk_submission.id), params: bulk_submission_form_params
        expect(response).to redirect_to(bulk_submissions_path)
      end

      it "updates the bulk submissions original file" do
        expect {
          patch bulk_submission_form_path(bulk_submission.id), params: bulk_submission_form_params
        }.to change {
          bulk_submission.reload.original_file.filename.to_s
        }.from('basic_bulk_submission.csv')
         .to('basic_bulk_submission_copy.csv')
      end
    end

    context "without file added and continue pressed" do
      let(:bulk_submission_form_params) { { commit: "continue" } }

      it "redirects to index" do
        patch bulk_submission_form_path(bulk_submission.id), params: bulk_submission_form_params
        expect(response).to redirect_to(bulk_submissions_path)
      end
    end

    # NOTE: this scenario cannot occur in the app but is used for coverage
    # In reality it should never be possible to have a bulk submission
    # with no original_file which is on the edit page.
    context "with invalid form and continue pressed" do
      let(:bulk_submission_form_params) { { commit: "continue" } }

      let(:bulk_submission) do
        BulkSubmission.create!(
          user_id: user.id,
          original_file: nil
        )
      end

      it "renders edit" do
        patch bulk_submission_form_path(bulk_submission.id), params: bulk_submission_form_params
        expect(response).to render_template(:edit)
        expect(response.body).to include("You must select a file to upload")
      end
    end
  end

  describe "DELETE /destroy" do
    before { bulk_submission }

    let(:bulk_submission) do
      BulkSubmission.create!(
        user_id: user.id,
        original_file: fixture_file_upload('basic_bulk_submission.csv')
      )
    end

    it "redirects to new" do
      delete "/bulk_submission_forms/#{bulk_submission.id}"
      expect(response).to redirect_to(new_bulk_submission_form_path)
    end

    it "purges the requested bulk_submission's attachments" do
      expect {
        delete "/bulk_submission_forms/#{bulk_submission.id}"
      }.to change(ActiveStorage::Attachment, :count).by(-1)
    end

    it "destroys the requested bulk_submission record" do
      expect {
        delete "/bulk_submission_forms/#{bulk_submission.id}"
      }.to change(BulkSubmission, :count).by(-1)
    end
  end
end
