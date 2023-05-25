require 'system_helper'

RSpec.describe BulkSubmissionsController, type: :request do
  before { sign_in user }

  let(:user) { create(:user) }

  let(:bulk_submission) do
    BulkSubmission.create!(
      user_id: user.id,
      original_file: fixture_file_upload('basic_bulk_submission.csv'),
      status: :pending,
    )
  end

  describe "GET /index" do
    it "returns http success" do
      get bulk_submissions_path
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:index)
      expect(response.body).to include("Checked details")
      expect(response.body).to include("Check new details")
    end
  end

  describe "DELETE /destroy" do
    before { bulk_submission }

    it "destroys the requested bulk_submission" do
      expect {
        delete bulk_submission_path(bulk_submission.id)
      }.to change(BulkSubmission, :count).by(-1)
    end

    it "destroys the requested bulk_submissions attachments" do
      expect {
        delete bulk_submission_path(bulk_submission.id)
      }.to change(ActiveStorage::Attachment, :count).by(-1)
    end

    it "redirects to bulk submissions index or authenticated root path" do
      get process_all_bulk_submissions_path
      expect(response)
        .to redirect_to(bulk_submissions_path)
        .or redirect_to(authenticated_root_path)
    end
  end

  describe "GET /process_all" do
    before { bulk_submission }

    it "enqueues BulkSubmissionsWorker job", type: :worker do
      expect { get process_all_bulk_submissions_path }
        .to change(BulkSubmissionsWorker, :jobs)
        .from([])
        .to(
          [
            hash_including(
              "retry" => true,
              "queue" => "default",
              "args" => [],
              "class" => "BulkSubmissionsWorker"
            )
          ]
        )
    end

    it "redirects to fallback location and renders flash" do
      get process_all_bulk_submissions_path
      expect(flash[:notice]).to match(/processing all pending bulk submissions/i)
      expect(response).to redirect_to(authenticated_root_path)
    end
  end
end
