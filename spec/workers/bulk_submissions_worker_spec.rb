require "rails_helper"

RSpec.describe BulkSubmissionsWorker, type: :worker do
  describe ".perform_async" do
    subject(:perform_async) { described_class.perform_async }

    it "enqueues 1 job with expected options" do
      expect { perform_async }
        .to change(described_class, :jobs)
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
  end

  describe "#perform" do
    subject(:perform) { described_class.new.perform }

    let(:bulk_submission) { create(:bulk_submission, :with_original_file, status: 'pending') }

    before { bulk_submission }

    it_behaves_like "applcation worker logger"

    it "enqueues BulkSubmissionWorker with ids" do
      allow(BulkSubmissionWorker).to receive(:perform_async)
      perform
      expect(BulkSubmissionWorker).to have_received(:perform_async).with(bulk_submission.id)
    end
  end
end
