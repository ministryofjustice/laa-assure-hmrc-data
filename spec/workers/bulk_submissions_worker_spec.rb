require "rails_helper"
require 'sidekiq/testing' # Warning: Requiring sidekiq/testing will automatically call Sidekiq::Testing.fake!, see https://github.com/sidekiq/sidekiq/wiki/Testing

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

    let(:log_regex) do
      %r{\[\d{4}-\d{2}-\d{2}\s*\d{2}:\d{2}:\d{2}.*\] running #{described_class} with args: \[\]}
    end

    before { bulk_submission }

    it "calls BulkSubmissionWorker with ids" do
      allow(BulkSubmissionWorker).to receive(:perform_async)
      perform
      expect(BulkSubmissionWorker).to have_received(:perform_async).with(bulk_submission.id)
    end

    it "logs timestamp, class and args of run" do
      allow(Rails.logger).to receive(:info)
      perform
      expect(Rails.logger).to have_received(:info).with(log_regex)
    end
  end
end

