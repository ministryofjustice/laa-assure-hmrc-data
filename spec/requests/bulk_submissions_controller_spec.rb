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

    context "with an undiscarded and a discarded bulk submission" do
      before do
        discarded
        undiscarded
      end

      let(:discarded) do
        create(:bulk_submission,
               :discarded,
               :pending,
               :with_original_file,
               original_file_fixture_name: "multiple_bulk_submission.csv",
               original_file_fixture_content_type: "text/csv",
               user_id: user.id)
      end

      let(:undiscarded) do
        create(:bulk_submission,
               :undiscarded,
               :pending,
               :with_original_file,
               original_file_fixture_name: "basic_bulk_submission.csv",
               original_file_fixture_content_type: "text/csv",
               user_id: user.id)
      end

      it "displays only undiscarded bulk submissions" do
        get bulk_submissions_path
        expect(response.body).to include("basic_bulk_submission.csv")
        expect(response.body).not_to include("multiple_bulk_submission.csv")
      end
    end

    context "with multiple bulk submissions from multiple days" do
      before do
        older
        newer
      end

      let(:newer) do
        create(:bulk_submission,
               :pending,
               :with_original_file,
               original_file_fixture_name: "multiple_bulk_submission.csv",
               original_file_fixture_content_type: "text/csv",
               user_id: user.id)
      end

      let(:older) do
        travel_to(1.day.ago) do
          create(:bulk_submission,
                 :ready,
                 :with_original_file,
                 :with_result_file,
                 original_file_fixture_name: "basic_bulk_submission.csv",
                 original_file_fixture_content_type: "text/csv",
                 user_id: user.id)
        end
      end

      it "displays bulk submissions, newest first, by date created" do
        get bulk_submissions_path
        expect(response.body).to match(/multiple_bulk_submission.csv.+basic_bulk_submission.csv/)
      end
    end
  end

  describe "DELETE /destroy" do
    before { bulk_submission }

    it "does not destroy any bulk_submission" do
      expect {
        delete bulk_submission_path(bulk_submission.id)
      }.to change(BulkSubmission, :count).by(0)
    end

    it "does not destroy any bulk_submissions attachments" do
      expect {
        delete bulk_submission_path(bulk_submission.id)
      }.to change(ActiveStorage::Attachment, :count).by(0)
    end

    it "discards the requested bulk_submission" do
      expect {
        delete bulk_submission_path(bulk_submission.id)
      }.to change { bulk_submission.reload.discarded? }
              .from(false)
              .to(true)
    end

    it "redirects to bulk submissions index or authenticated root path" do
      delete bulk_submission_path(bulk_submission.id)
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
      expect(response)
        .to redirect_to(bulk_submissions_path)
        .or redirect_to(authenticated_root_path)
    end
  end
end
