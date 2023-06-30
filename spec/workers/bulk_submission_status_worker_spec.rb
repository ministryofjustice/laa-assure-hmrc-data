require "rails_helper"

RSpec.describe BulkSubmissionStatusWorker, type: :worker do
  describe ".sidekiq_retries_exhausted" do
    subject(:config) { described_class }

    let(:bulk_submission) { create(:bulk_submission, :processing) }

    let(:job) do
      {
        "class" => described_class,
        "args" => [bulk_submission.id],
        "error_message" => "oops, I did it again!"
      }
    end

    let(:exc) { StandardError.new("doh!") }

    before { allow(Sentry).to receive(:capture_message) }

    it "updates status of bulk_submission to \"exhausted\"" do
      expect {
        config.sidekiq_retries_exhausted_block.call(job, exc)
      }.to change { bulk_submission.reload.status }.from("processing").to(
        "exhausted"
      )
    end

    it "send failure message to sentry" do
      config.sidekiq_retries_exhausted_block.call(job, exc)
      expect(Sentry).to have_received(:capture_message).with(
        /Failed #{job["class"]} for bulk_submission \["#{bulk_submission.id}"\]: oops, I did it again!.*/
      )
    end
  end

  describe ".perform_async" do
    subject(:perform_async) do
      described_class.perform_async(bulk_submission.id)
    end

    let(:bulk_submission) { create(:bulk_submission, :with_original_file) }

    it "enqueues 1 job with expected options" do
      expect { perform_async }.to change(described_class, :jobs).from([]).to(
        [
          hash_including(
            "retry" => 6,
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
          bs.submissions << create(
            :submission,
            use_case: :one,
            status: "exhausted"
          )
          bs.submissions << create(
            :submission,
            use_case: :two,
            status: "completed"
          )
          bs.submissions << create(
            :submission,
            use_case: :one,
            status: "failed"
          )
        end
      end

      it_behaves_like "application worker logger"

      it "calls BulkSubmissionResultWriterWorker with id" do
        allow(BulkSubmissionResultWriterWorker).to receive(:perform_async)
        perform
        expect(BulkSubmissionResultWriterWorker).to have_received(
          :perform_async
        ).with(bulk_submission.id)
      end
    end

    context "when bulk_submission is NOT finished?" do
      let(:bulk_submission) do
        create(:bulk_submission).tap do |bs|
          bs.submissions.destroy_all
          bs.submissions << create(
            :submission,
            use_case: :one,
            status: "processing"
          )
        end
      end

      it "raise TryAgain error" do
        expect { perform }.to raise_error(
          WorkerErrors::TryAgain,
          "waiting for bulk_submission with id #{bulk_submission.id} to complete..."
        )
      end
    end

    context "when bulk_submission has no submissions" do
      let(:bulk_submission) do
        create(:bulk_submission).tap { |bs| bs.submissions.destroy_all }
      end

      it "raise TryAgain error" do
        expect { perform }.to raise_error(
          WorkerErrors::TryAgain,
          "waiting for bulk_submission with id #{bulk_submission.id} to complete..."
        )
      end
    end
  end
end
