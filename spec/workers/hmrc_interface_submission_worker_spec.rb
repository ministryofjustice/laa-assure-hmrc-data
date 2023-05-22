require "rails_helper"
require 'sidekiq/testing' # Warning: Requiring sidekiq/testing will automatically call Sidekiq::Testing.fake!, see https://github.com/sidekiq/sidekiq/wiki/Testing

RSpec.describe HmrcInterfaceSubmissionWorker, type: :worker do
  let(:submission) { create(:submission) }

  # TODO: move to shared example and us for all subclasses of hrmc_interface_base_worker
  describe '.retry' do
    subject(:retry) { described_class.get_sidekiq_options['retry'] }

    it { is_expected.to be 10 }
  end

  # TODO: move to shared example and us for all subclasses of hrmc_interface_base_worker
  describe '.sidekiq_retry_in' do
    subject(:config) { described_class }

    context "when try again error raised" do
      let(:exc) { HmrcInterface::TryAgain.new('only me') }

      it 'delays the first retry for 5 seconds' do
        expect(config.sidekiq_retry_in_block.call(1, exc)).to eq 5
      end

      it 'delays the second retry for 10 seconds' do
        expect(config.sidekiq_retry_in_block.call(2, exc)).to eq 10
      end

      it 'delays the tenth retry for 50 seconds' do
        expect(config.sidekiq_retry_in_block.call(10, exc)).to eq 50
      end
    end

    context "when incomplete result error raised" do
      let(:exc) { HmrcInterface::IncompleteResult.new('only me') }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error message and sends :kill to move job to deadset' do
        expect(config.sidekiq_retry_in_block.call(1, exc)).to eq :kill
        expect(Rails.logger).to have_received(:error).with("only me")
      end
    end

    context "when request unacceptable result error raised" do
      let(:exc) { HmrcInterface::RequestUnacceptable.new('only me') }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error message and sends :kill to move job to deadset' do
        expect(config.sidekiq_retry_in_block.call(1, exc)).to eq :kill
        expect(Rails.logger).to have_received(:error).with("only me")
      end
    end

    context "when other error raised" do
      let(:exc) { StandardError.new('oops') }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'sends nil to pickup sidekiq default interval alorithm' do
        expect(config.sidekiq_retry_in_block.call(1, exc)).to be_nil
      end
    end
  end

  # TODO: move to shared example and us for all subclasses of hrmc_interface_base_worker
  describe '.sidekiq_retries_exhausted' do
    subject(:config) { described_class }

    let(:job) do
      {
        "class" => described_class,
        "args" => ["whatever"],
        "error_message" => "oops, I did it again!"
      }
    end

    let(:exc) { StandardError.new("oh oh!") }

    before do
      allow(Sentry).to receive(:capture_message)
    end

    it 'delays the first retry for 5 seconds' do
      config.sidekiq_retries_exhausted_block.call(job, exc)
      expect(Sentry)
        .to have_received(:capture_message)
        .with(
          "Failed #{job['class']} with [\"whatever\"]: oops, I did it again!"
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
                    "retry" => 10,
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
                    "retry" => 10,
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
