require "rails_helper"

RSpec.describe HmrcInterfaceBulkSubmissionWorker, type: :worker do
  describe ".perform_async" do
    subject(:perform_async) { described_class.perform_async }

    it "enqueues 1 job with expected options" do
      expect { perform_async }.to change(described_class, :jobs).from([]).to(
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
  end

  describe "#perform" do
    subject(:perform) { described_class.new.perform(bulk_submission.id) }

    let(:bulk_submission) do
      create(:bulk_submission, status: "pending") do |bs|
        bs.submissions << create(:submission, status: :pending, use_case: :one)
        bs.submissions << create(:submission, status: :pending, use_case: :two)
      end
    end

    let(:worker) { class_double(HmrcInterfaceSubmissionWorker) }

    before do
      allow(HmrcInterfaceSubmissionWorker).to receive(:set).and_return(worker)
      allow(worker).to receive(:perform_async)
    end

    it_behaves_like "application worker logger"

    it "updates status to :processing" do
      expect { perform }.to change { bulk_submission.reload.status }.from(
        "pending"
      ).to("processing")
    end

    it "enqueues HmrcInterfaceSubmissionWorker on uc-one-submissions queue with submission's id" do
      perform
      expect(HmrcInterfaceSubmissionWorker).to have_received(:set).with(
        queue: "uc-one-submissions"
      ).once
      expect(worker).to have_received(:perform_async).with(
        bulk_submission.submissions.first.id,
        instance_of(Integer)
      )
    end

    it "enqueues HmrcInterfaceSubmissionWorker on uc-two-submissions queue with submission's id" do
      perform
      expect(HmrcInterfaceSubmissionWorker).to have_received(:set).with(
        queue: "uc-two-submissions"
      ).once
      expect(worker).to have_received(:perform_async).with(
        bulk_submission.submissions.second.id,
        instance_of(Integer)
      )
    end
  end
end
