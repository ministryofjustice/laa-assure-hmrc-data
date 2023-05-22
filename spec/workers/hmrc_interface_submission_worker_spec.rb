require "rails_helper"
require 'sidekiq/testing' # Warning: Requiring sidekiq/testing will automatically call Sidekiq::Testing.fake!, see https://github.com/sidekiq/sidekiq/wiki/Testing

RSpec.describe HmrcInterfaceSubmissionWorker, type: :worker do
  let(:submission) { create(:submission) }

  it_behaves_like "hmrc interface worker"

  describe '.sidekiq_retries_exhausted' do
    subject(:config) { described_class }

    let(:job) do
      {
        "class" => described_class,
        "args" => ["whatever"],
        "error_message" => "oops, I did it again!"
      }
    end

    let(:exc) { StandardError.new("doh!") }

    before do
      allow(Sentry).to receive(:capture_message)
    end

    it 'send failure message to sentry' do
      config.sidekiq_retries_exhausted_block.call(job, exc)
      expect(Sentry)
        .to have_received(:capture_message)
        .with(
          %r{Failed #{job['class']} with \["whatever"\]: oops, I did it again!.*}
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
                    "class" => "HmrcInterfaceSubmissionWorker"
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
                    "class" => "HmrcInterfaceSubmissionWorker"
                  )
                ]
            )
      end
    end

    # TODO: while this works it redifines the class rendering described_class unusable
    # and leaking to subsequent tests
    # xcontext "when on uat host" do
    #   subject(:perform_async) { described_class.set(queue:).perform_async(submission.id) }
    #
    #   let(:queue) { "uc-one-submissions" }
    #
    #   before do
    #     allow(Rails.configuration.x).to receive(:host_env).and_return "uat"
    #     allow(Rails.configuration.x.status).to receive(:app_branch).and_return "my-branch"

    #     # reload class to pickup config stubs
    #     location = Module.const_source_location(described_class.to_s)
    #     Object.send(:remove_const, described_class.to_s)
    #     load location.first
    #   end

    #   # NOTE: we need to refer to the class by name hereafter to
    #   # ensure we pick up the reloaded class. described_class cannot
    #   # be reset :(
    #   it "enqueues 1 job with expected options, including branch specific queue" do
    #     expect { HmrcInterfaceSubmissionWorker..set(queue:).perform_async(submission.id) }
    #       .to change(described_class, :jobs)
    #         .from([])
    #         .to(
    #             [
    #               hash_including(
    #                 "retry" => 10,
    #                 "queue" => "uc-one-submissions-my-branch",
    #                 "args" => [submission.id],
    #                 "class" => "HmrcInterfaceSubmissionWorker"
    #               )
    #             ]
    #         )
    #   end
    # end
  end

  describe "#perform" do
    subject(:perform) { described_class.new.perform(submission.id) }

    before do
      allow(HmrcInterfaceSubmissionService).to receive(:call)
    end

    it_behaves_like "applcation worker logger"

    it "calls HmrcInterfaceSubmissionService" do
      perform
      expect(HmrcInterfaceSubmissionService).to have_received(:call).with(submission.id).once
    end
  end
end
