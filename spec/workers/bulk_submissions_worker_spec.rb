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
    #     expect { BulkSubmissionsWorker.perform_async }
    #       .to change(described_class, :jobs)
    #         .from([])
    #         .to(
    #             [
    #               hash_including(
    #                 "retry" => true,
    #                 "queue" => "default-my-branch",
    #                 "args" => [],
    #                 "class" => "BulkSubmissionsWorker"
    #               )
    #             ]
    #         )
    #   end
    # end
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
