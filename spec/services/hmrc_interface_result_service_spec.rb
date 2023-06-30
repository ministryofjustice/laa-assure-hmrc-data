require "rails_helper"

RSpec.describe HmrcInterfaceResultService do
  subject(:instance) { described_class.new(submission.id) }

  let(:submission) do
    create(
      :submission,
      status: :submitted,
      use_case: :one,
      hmrc_interface_id: "5ae37a62-59af-4eab-a995-c99ebe994f39"
    )
  end

  describe "#submission" do
    it { expect(instance.submission).to eql(submission) }
  end

  describe "#requestor" do
    subject(:requestor) { instance.requestor }

    it "defaults to HmrcInterface::Request::Result" do
      expect(requestor).to be HmrcInterface::Request::Result
    end
  end

  describe "#call" do
    subject(:call) { instance.call }

    include_context "with stubbed host and bearer token"

    context "when result has completed status" do
      before do
        allow(instance.requestor).to receive(:call).and_return(parsed_response)
      end

      let(:parsed_response) do
        file =
          file_fixture(
            "results/hmrc_interface_successful_result_response_body.json"
          )
        raw_response = file.read
        JSON.parse(raw_response, symbolize_names: true)
      end

      it "updates submission status to completed" do
        expect { call }.to change { submission.reload.status }.from(
          "submitted"
        ).to("completed")
      end

      it "updates submission hmrc_interface_result to parsed response body",
         :aggregate_failures do
        expect { call }.to change {
          JSON.parse(
            submission.reload.hmrc_interface_result.to_json,
            symbolize_names: true
          )
        }.from("{}").to(parsed_response)
      end
    end

    context "when result has processing status" do
      before do
        allow(instance.requestor).to receive(:call).and_return(
          parsed_processing_response
        )
      end

      let(:parsed_processing_response) { { status: "processing" } }

      it "raises kind of StandardError with message" do
        expect { call }.to raise_error(
          a_kind_of(StandardError),
          "still processing submission: #{submission.id} with hmrc interface id #{submission.hmrc_interface_id}"
        )
      end

      it "updates status to processing and hmrc_interface_result to returned payload" do
        call
      rescue StandardError
        expect(submission.reload.status).to eql("processing")
        expect(submission.reload.hmrc_interface_result).to eql(
          parsed_processing_response.as_json
        )
      end
    end

    context "when result has created status" do
      before do
        allow(instance.requestor).to receive(:call).and_return(
          parsed_processing_response
        )
      end

      let(:parsed_processing_response) { { status: "created" } }

      it "raises kind of StandardError with message" do
        expect { call }.to raise_error(
          a_kind_of(StandardError),
          "still processing submission: #{submission.id} with hmrc interface id #{submission.hmrc_interface_id}"
        )
      end

      it "updates status to processing and hmrc_interface_result to returned payload" do
        call
      rescue StandardError
        expect(submission.reload.status).to eql("created")
        expect(submission.reload.hmrc_interface_result).to eql(
          parsed_processing_response.as_json
        )
      end
    end

    context "when result has unexpected status" do
      before do
        allow(instance.requestor).to receive(:call).and_return(
          parsed_processing_response
        )
      end

      let(:parsed_processing_response) { { status: "foobar" } }

      it "raises kind of StandardError with message" do
        expect { call }.to raise_error(
          a_kind_of(StandardError),
          "still processing submission: #{submission.id} with hmrc interface id #{submission.hmrc_interface_id}"
        )
      end

      it "updates status to processing and hmrc_interface_result to returned payload" do
        call
      rescue StandardError
        expect(submission.reload.status).to eql("foobar")
        expect(submission.reload.hmrc_interface_result).to eql(
          parsed_processing_response.as_json
        )
      end
    end

    context "when result request raises error" do
      before do
        allow(instance.requestor).to receive(:call).and_raise StandardError,
                    "oops, something went wrong"
      end

      it "allows error to go unhandled (so sidekiq job can retry)" do
        expect { call }.to raise_error StandardError,
                    "oops, something went wrong"

        expect(submission.reload.hmrc_interface_result).to eql("{}")
        expect(submission.reload.status).to eql("completing")
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
