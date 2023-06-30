require "rails_helper"

RSpec.describe BulkSubmissionsWorker, type: :worker do
  describe ".perform_async" do
    subject(:perform_async) { described_class.perform_async }

    it "enqueues 1 job with expected options" do
      expect { perform_async }.to change(described_class, :jobs).from([]).to(
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

    let(:bulk_submission) do
      create(:bulk_submission, :with_original_file, status: "pending")
    end

    context "with one undiscarded pending bulk submission" do
      before { bulk_submission }

      let(:bulk_submission) do
        create(:bulk_submission, :undiscarded, :pending, :with_original_file)
      end

      it_behaves_like "application worker logger"

      it "enqueues BulkSubmissionWorker with ids" do
        allow(BulkSubmissionWorker).to receive(:perform_async)
        perform
        expect(BulkSubmissionWorker).to have_received(:perform_async).with(
          bulk_submission.id
        )
      end
    end

    context "with one discarded pending bulk submission" do
      before { bulk_submission }

      let(:bulk_submission) do
        create(:bulk_submission, :discarded, :pending, :with_original_file)
      end

      it_behaves_like "application worker logger"

      it "does NOT enqueue a BulkSubmissionWorker for the bulk submission" do
        allow(BulkSubmissionWorker).to receive(:perform_async)
        perform
        expect(BulkSubmissionWorker).not_to have_received(:perform_async)
      end
    end
  end
end
