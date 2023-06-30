require "rails_helper"

RSpec.describe BulkSubmissionWorker, type: :worker do
  describe ".perform_async" do
    subject(:perform_async) do
      described_class.perform_async(bulk_submission.id)
    end

    let(:bulk_submission) { create(:bulk_submission, :with_original_file) }

    it "enqueues 1 job with expected options" do
      expect { perform_async }.to change(described_class, :jobs).from([]).to(
        [
          hash_including(
            "retry" => true,
            "queue" => "default",
            "args" => [bulk_submission.id],
            "class" => "BulkSubmissionWorker"
          )
        ]
      )
    end
  end

  describe "#perform" do
    subject(:perform) { described_class.new.perform(bulk_submission.id) }

    let(:bulk_submission) { create(:bulk_submission, :with_original_file) }

    it_behaves_like "application worker logger"

    it "calls BulkSubmissionService with id" do
      allow(BulkSubmissionService).to receive(:call)
      perform
      expect(BulkSubmissionService).to have_received(:call).with(
        bulk_submission
      )
    end
  end
end
