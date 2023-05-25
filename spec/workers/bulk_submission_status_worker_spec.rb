require "rails_helper"
require 'sidekiq/testing' # Warning: Requiring sidekiq/testing will automatically call Sidekiq::Testing.fake!, see https://github.com/sidekiq/sidekiq/wiki/Testing

RSpec.describe BulkSubmissionStatusWorker, type: :worker do
  describe ".perform_async" do
    subject(:perform_async) { described_class.perform_async(bulk_submission.id) }

    let(:bulk_submission) { create(:bulk_submission, :with_original_file) }

    it "enqueues 1 job with expected options" do
      expect { perform_async }
        .to change(described_class, :jobs)
          .from([])
          .to(
              [
                hash_including(
                  "retry" => true,
                  "queue" => "default",
                  "args" => [bulk_submission.id],
                  "class" => "BulkSubmissionStatusWorker"
                )
              ]
          )
    end
  end

  describe "#perform" do
    subject(:perform) { described_class.new.perform(bulk_submission.id) }

    let(:bulk_submission) { create(:bulk_submission) }

    context "when bulk_submission's submissions are all finished" do
      let(:bulk_submission) do
        create(:bulk_submission).tap do |bs|
          bs.submissions.destroy_all
          bs.submissions << create(:submission, use_case: :one, status: 'exhausted')
          bs.submissions << create(:submission, use_case: :two, status: 'completed')
          bs.submissions << create(:submission, use_case: :one, status: 'failed')
        end
      end

      it_behaves_like "applcation worker logger"

      it "calls BulkSubmissionResultWriterWorker with id" do
        allow(BulkSubmissionResultWriterWorker).to receive(:perform_async)
        perform
        expect(BulkSubmissionResultWriterWorker).to have_received(:perform_async).with(bulk_submission.id)
      end
    end

    context "when bulk_submission is NOT finished?" do
      let(:bulk_submission) do
        create(:bulk_submission).tap do |bs|
          bs.submissions.destroy_all
          bs.submissions << create(:submission, use_case: :one, status: 'processing')
        end
      end

      it "raise TryAgain error" do
        expect { perform }.to raise_error(WorkerErrors::TryAgain,
                                          "waiting for bulk_submission with id #{bulk_submission.id} to complete...")
      end
    end

    context "when bulk_submission has no submissions" do
      let(:bulk_submission) do
        create(:bulk_submission).tap do |bs|
          bs.submissions.destroy_all
        end
      end

      it "raise TryAgain error" do
        expect { perform }.to raise_error(WorkerErrors::TryAgain,
                                         "waiting for bulk_submission with id #{bulk_submission.id} to complete...")
      end
    end
  end
end

