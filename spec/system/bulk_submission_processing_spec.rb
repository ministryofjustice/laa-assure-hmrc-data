require "rails_helper"

RSpec.describe "Processing of a bulk submission", type: :worker do
  subject(:perform_inline) do
    Sidekiq::Testing.inline! do
      BulkSubmissionsWorker.perform_async
    end
  end

  context "with a large valid format file" do
    include_context "with stubbed hmrc-interface submission created"
    include_context "with stubbed hmrc-interface result completed"

    before do
      bulk_submission
    end

    let(:bulk_submission) do
      BulkSubmission.create!(
        user_id: user.id,
        original_file: fixture_file_upload('large_valid_bulk_submission.csv'),
        status: :pending,
      )
    end

    let(:user) { create(:user) }

    it "creates 2 x rows submission records and populates result for each" do
      expect { perform_inline }.to change(Submission, :count).by(70)

      submissions = bulk_submission.submissions
      expect(submissions.pluck(:status)).to all(eql("completed"))
      expect(submissions.pluck(:hmrc_interface_result)).to all(be_present)

      bulk_submission.reload

      expect(bulk_submission).to be_finished
      expect(bulk_submission).to be_ready
    end
  end
end
