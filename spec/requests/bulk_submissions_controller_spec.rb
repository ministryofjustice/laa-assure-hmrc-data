require 'system_helper'

RSpec.describe BulkSubmissionsController, type: :request do
  before { sign_in user }

  let(:user) { create(:user) }

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

    let(:bulk_submission) do
      BulkSubmission.create!(
        user_id: user.id,
        original_file: fixture_file_upload('basic_bulk_submission.csv')
      )
    end

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
  end
end
