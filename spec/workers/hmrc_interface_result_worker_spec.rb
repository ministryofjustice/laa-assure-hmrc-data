require "rails_helper"
require 'sidekiq/testing' # Warning: Requiring sidekiq/testing will automatically call Sidekiq::Testing.fake!, see https://github.com/sidekiq/sidekiq/wiki/Testing

RSpec.describe HmrcInterfaceResultWorker, type: :worker do
  let(:submission) { create(:submission, status: :submitted) }

  it_behaves_like "hmrc interface worker"

  describe '.sidekiq_retries_exhausted' do
    subject(:config) { described_class }

    let(:job) do
      {
        "class" => described_class,
        "args" => [submission.id],
        "error_message" => "oops, I did it again!"
      }
    end

    let(:exc) { StandardError.new("doh!") }

    before do
      allow(Sentry).to receive(:capture_message)
    end

    it "updates status of submission to \"exhausted\"" do
      expect { config.sidekiq_retries_exhausted_block.call(job, exc) }
        .to change { submission.reload.status }
        .from("submitted")
        .to("exhausted")
    end

    it 'send failure message to sentry' do
      config.sidekiq_retries_exhausted_block.call(job, exc)
      expect(Sentry)
        .to have_received(:capture_message)
        .with(
          %r{Failed #{job['class']} for submission \["#{submission.id}"\]: oops, I did it again!.*}
        )
    end
  end

  describe ".perform_async" do
    context "when queue set by caller" do
      subject(:perform_async) { described_class.set(queue:).perform_async(submission.id) }

      let(:queue) { "uc-one-submissions" }

      it "enqueues 1 job with expected options on supplied queue" do
        expect { perform_async }
          .to change(described_class, :jobs)
            .from([])
            .to(
                [
                  hash_including(
                    "retry" => 5,
                    "queue" => "uc-one-submissions",
                    "args" => [submission.id],
                    "class" => "HmrcInterfaceResultWorker"
                  )
                ]
            )
      end
    end

    context "when queue not set by caller" do
      subject(:perform_async) { described_class.perform_async(submission.id) }

      it "enqueues 1 job with expected options on default queue" do
        expect { perform_async }
          .to change(described_class, :jobs)
            .from([])
            .to(
                [
                  hash_including(
                    "retry" => 5,
                    "queue" => "default",
                    "args" => [submission.id],
                    "class" => "HmrcInterfaceResultWorker"
                  )
                ]
            )
      end
    end
  end

  describe "#perform" do
    subject(:perform) { described_class.new.perform(submission.id) }

    before do
      allow(HmrcInterfaceResultService).to receive(:call)
    end

    it_behaves_like "applcation worker logger"

    it "calls HmrcInterfaceResultService with submission id" do
      perform
      expect(HmrcInterfaceResultService).to have_received(:call).with(submission.id).once
    end
  end
end
