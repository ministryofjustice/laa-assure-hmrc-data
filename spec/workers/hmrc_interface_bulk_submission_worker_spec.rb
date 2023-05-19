require "rails_helper"
require 'sidekiq/testing' # Warning: Requiring sidekiq/testing will automatically call Sidekiq::Testing.fake!, see https://github.com/sidekiq/sidekiq/wiki/Testing

RSpec.describe HmrcInterfaceBulkSubmissionWorker, type: :worker do
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
                  "class" => "HmrcInterfaceBulkSubmissionWorker"
                )
              ]
          )
    end

    # TODO: while this works it redifines the class rendering described_class unusable
    # and leaking to subsequent tests
    # xcontext "when on uat host" do
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
    #     expect { HmrcInterfaceBulkSubmissionWorker.perform_async }
    #       .to change(described_class, :jobs)
    #         .from([])
    #         .to(
    #             [
    #               hash_including(
    #                 "retry" => true,
    #                 "queue" => "default-my-branch",
    #                 "args" => [],
    #                 "class" => "HmrcInterfaceBulkSubmissionWorker"
    #               )
    #             ]
    #         )
    #   end
    # end
  end

  describe "#perform" do
    subject(:perform) { described_class.new.perform(bulk_submission.id) }

    let(:bulk_submission) do
      create(:bulk_submission, status: 'pending') do |bs|
        bs.submissions << create(:submission, status: :pending, use_case: :one)
        bs.submissions << create(:submission, status: :pending, use_case: :two)
      end
    end

    # TODO: move to shared context or example
    let(:log_regex) do
      %r{\[\d{4}-\d{2}-\d{2}\s*\d{2}:\d{2}:\d{2}.*\] running #{described_class} with args: \[.*\]}
    end

    # TODO: move to shared example
    let(:worker) { class_double(HmrcInterfaceSubmissionWorker) }

    before do
      allow(HmrcInterfaceSubmissionWorker).to receive(:set).and_return(worker)
      allow(worker).to receive(:perform_async)
    end

    it "updates status to :processing" do
      expect { perform }
        .to change { bulk_submission.reload.status }
              .from("pending")
              .to("processing")
    end

    it "enqueues HmrcInterfaceSubmissionWorker on uc-one-submissions queue passing submission's id" do
      perform
      expect(HmrcInterfaceSubmissionWorker).to have_received(:set).with(queue: "uc-one-submissions").once
      expect(worker).to have_received(:perform_async).with(bulk_submission.submissions.first.id)
    end

    it "enqueues HmrcInterfaceSubmissionWorker on uc-two-submissions queue passing submission's id" do
      perform
      expect(HmrcInterfaceSubmissionWorker).to have_received(:set).with(queue: "uc-two-submissions").once
      expect(worker).to have_received(:perform_async).with(bulk_submission.submissions.second.id)
    end

    # TODO: move to shared example
    it "logs timestamp, class and args of run" do
      allow(Rails.logger).to receive(:info)
      perform
      expect(Rails.logger).to have_received(:info).with(log_regex)
    end
  end
end
