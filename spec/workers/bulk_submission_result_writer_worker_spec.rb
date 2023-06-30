require "rails_helper"

RSpec.describe BulkSubmissionResultWriterWorker, type: :worker do
  before { allow(BulkSubmissionResultWriterService).to receive(:call) }

  describe ".perform_async" do
    subject(:perform_async) { described_class.perform_async("an-id") }

    it "enqueues 1 job with expected options" do
      expect { perform_async }.to change(described_class, :jobs).from([]).to(
        [
          hash_including(
            "retry" => true,
            "queue" => "default",
            "args" => ["an-id"],
            "class" => "BulkSubmissionResultWriterWorker"
          )
        ]
      )
    end
  end

  describe "#perform" do
    subject(:perform) { described_class.new.perform("an-id") }

    it_behaves_like "application worker logger"

    it "calls BulkSubmissionResultWriterService with id" do
      perform
      expect(BulkSubmissionResultWriterService).to have_received(:call).with(
        "an-id"
      )
    end
  end
end
