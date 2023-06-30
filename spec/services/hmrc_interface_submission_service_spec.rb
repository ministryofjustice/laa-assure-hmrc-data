require "rails_helper"

RSpec.describe HmrcInterfaceSubmissionService do
  subject(:instance) { described_class.new(submission.id) }

  let(:submission) { create(:submission, status: :pending, use_case: :one) }

  describe "#submission" do
    it { expect(instance.submission).to eql(submission) }
  end

  describe "#requestor" do
    subject(:requestor) { instance.requestor }

    it "defaults to HmrcInterface::Request::Result" do
      expect(requestor).to be HmrcInterface::Request::Submission
    end
  end

  describe "#number_in_queue" do
    subject(:number_in_queue) { instance.number_in_queue }

    it "defaults to 0" do
      expect(number_in_queue).to be_zero
    end

    context "when number_in_queue supplied" do
      let(:instance) { described_class.new(submission.id, 35) }

      it "returns the number_in_queue it was initialised with" do
        expect(number_in_queue).to be 35
      end
    end
  end

  describe "#call" do
    subject(:call) { instance.call }

    include_context "with stubbed host and bearer token"

    context "with a submission success" do
      before do
        allow(instance.requestor).to receive(:call).and_return(response_with_id)
      end

      let(:response_with_id) { { id: "5ae37a62-59af-4eab-a995-c99ebe994f39" } }

      it "updates submission status to submitted" do
        expect { call }.to change { submission.reload.status }.from(
          "pending"
        ).to("submitted")
      end

      it "updates submission hmrc_interface_id to responses :id" do
        expect { instance.call }.to change {
          submission.reload.hmrc_interface_id
        }.from(nil).to("5ae37a62-59af-4eab-a995-c99ebe994f39")
      end

      context "with use_case one submission" do
        let(:submission) do
          create(:submission, status: :pending, use_case: :one)
        end
        let(:worker) { class_double(HmrcInterfaceResultWorker) }

        before do
          allow(HmrcInterfaceResultWorker).to receive(:set).and_return(worker)
          allow(worker).to receive(:perform_in)
        end

        it "enqueues HmrcInterfaceResultWorker on uc-one-submissions queue to be performed in 10 seconds" do
          call
          expect(HmrcInterfaceResultWorker).to have_received(:set).with(
            queue: "uc-one-submissions"
          ).once
          expect(worker).to have_received(:perform_in).with(
            7.seconds,
            submission.id
          ).once
        end
      end

      context "with use_case two submission" do
        let(:submission) do
          create(:submission, status: :pending, use_case: :two)
        end
        let(:worker) { class_double(HmrcInterfaceResultWorker) }

        before do
          allow(HmrcInterfaceResultWorker).to receive(:set).and_return(worker)
          allow(worker).to receive(:perform_in)
        end

        it "enqueues HmrcInterfaceResultWorker on uc-two-submissions queue to be performed in 10 seconds" do
          call
          expect(HmrcInterfaceResultWorker).to have_received(:set).with(
            queue: "uc-two-submissions"
          ).once
          expect(worker).to have_received(:perform_in).with(
            7.seconds,
            submission.id
          ).once
        end
      end
    end

    context "when submission request returns erroroneous response" do
      before do
        allow(instance.requestor).to receive(:call).and_return(
          response_without_id
        )
      end

      let(:response_without_id) { { foo: "bar" } }

      it "updates submission status to submitting" do
        expect { call }.to change { submission.reload.status }.from(
          "pending"
        ).to("submitting")
      end

      it "does not update submission hmrc_interface_id" do
        expect { call }.not_to change {
          submission.reload.hmrc_interface_id
        }.from(nil)
      end
    end

    context "when submission request raises error" do
      before do
        allow(instance.requestor).to receive(:call).and_raise StandardError,
                    "oops, something went wrong"
      end

      it "allows error to go unhandled (so sidekiq job can retry)" do
        expect { call }.to raise_error StandardError,
                    "oops, something went wrong"

        expect(submission.reload.hmrc_interface_id).to be_nil
        expect(submission.reload.status).to eql("submitting")
      end
    end
  end

  describe ".call" do
    subject(:call) { described_class.call(submission.id) }

    let(:instance) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:call)
    end

    it "sends call method to instance" do
      call
      expect(described_class).to have_received(:new).with(submission.id)
      expect(instance).to have_received(:call)
    end
  end
end
