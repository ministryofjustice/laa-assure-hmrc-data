require "rails_helper"

RSpec.describe HmrcInterface::Request::Result do
  subject(:instance) { described_class.new(client, submission_id) }

  let(:client) { HmrcInterface.client }
  let(:submission_id) { "fake-hmrc-interface-submission-id" }

  describe "#call" do
    subject(:call) { instance.call }

    context "when a successful \"completed\" response is received" do
      include_context "with stubbed hmrc-interface result completed"
      include_context "with nil access token"

      it "submits expected token request" do
        call

        expect(
          a_request(
            :post,
            "#{fake_host}/oauth/token"
          ).with(body: "grant_type=client_credentials",
                 headers: { 'Accept'=>'*/*',
                            'Content-Type'=>'application/x-www-form-urlencoded',
                            'Accept-Encoding'=>/.*/,
                            'Authorization'=>/Basic .*/ })
        ).to have_been_made.at_least_once
      end

      it "submits expected submission result request" do
        call

        expect(
          a_request(
            :get,
            "#{fake_host}/api/v1/submission/result/#{submission_id}"
          ).with(headers: { 'Accept'=>'application/json',
                            'Content-Type'=>'application/json',
                            'Accept-Encoding'=>/.*/,
                            'Authorization'=>'Bearer test-bearer-token',
                            'User-Agent'=>'laa-hmrc-interface-client/0.0.1'})
        ).to have_been_made.once
      end

      it "returns expected parsed JSON response" do
        file = file_fixture("results/hmrc_interface_successful_result_response_body.json")
        json = file.read
        parsed_json = JSON.parse(json, symbolize_names: true)

        expect(call).to match(parsed_json)
      end
    end

    context "when a \"processing\" response is received" do
      include_context "with stubbed host and bearer token"

      before do
        stub_request(:get, %r{#{fake_host}/api/v1/submission/result/.*})
          .to_return(
            status: 202,
            body: expected_body.to_json,
            headers: { "Content-Type" => "application/json; charset=utf-8" },
          )
      end

      let(:expected_body) do
        {
          submission: "fake-hmrc-interface-submission-id",
          status: "processing",
          _links: [href: "#{fake_host}/api/v1/submission/status/#{submission_id}"]
        }
      end

      it "returns expected parsed JSON response" do
        expect(call).to match(expected_body)
      end
    end

    context "when a \"failed\" response is received (client details not found)" do
      include_context "with stubbed host and bearer token"

      before do
        stub_request(:get, %r{#{fake_host}/api/v1/submission/result/.*})
          .to_return(
            status: 200,
            body: expected_body.to_json,
            headers: { "Content-Type" => "application/json; charset=utf-8" },
          )
      end

      let(:expected_body) do
        {
          submission: "fake-hmrc-interface-submission-id",
          status: "processing",
          data: [
            { correlation_id: submission_id, use_case: "use_case_one" },
            { error: "submitted client details could not be found in HMRC service" },
          ]
        }
      end

      it "returns expected parsed JSON response" do
        expect(call).to match(expected_body)
      end
    end

    # taken from hmrc interface `submissions_controller#result` action
    context "when an :internal_server_error is received" do
      include_context "with stubbed host and bearer token"

      before do
        stub_request(:get, %r{#{fake_host}/api/v1/submission/result/.*})
          .to_return(
            status: 500,
            body: expected_body.to_json,
            headers: { "Content-Type" => "application/json; charset=utf-8" },
          )
      end

      let(:expected_body) do
        {
          submission: "fake-hmrc-interface-submission-id",
          status: "processing",
          code: "INCOMPLETE_SUBMISSION",
          message: "Process complete but no result available"
        }
      end

      it "raises HmrcInterface::RequestUnacceptable error with expected message" do
          expect { call }
            .to raise_error(HmrcInterface::IncompleteResult,
                            "URL: #{fake_host}/api/v1/submission/result/fake-hmrc-interface-submission-id, status: 500, details: #{expected_body}")
        end
    end

    context "when an error occurs in authentication" do
      include_context "with stubbed host"
      include_context "with nil access token"

      context "with invalid credentials" do
        before do
          stub_request(:post, %r{#{fake_host}/oauth/token})
            .to_raise(OAuth2::Error)
        end

        it "logs the exception as information and raises HmrcInterface::RequestError error" do
          allow(Rails.logger).to receive(:info).and_call_original

          expect { call }.to raise_error HmrcInterface::RequestError, /#{described_class} received OAuth2::Error/

          expect(Rails.logger)
            .to have_received(:info) do |&block|
                  expect(block.call)
                    .to include(message:/#{described_class} received OAuth2::Error/)
                    .and include(backtrace: /.*/)
                    .and include(http_method: "GET")
                    .and include(http_status: nil)
                end
        end
      end
    end

    context "when an error occurs in the submission result process" do
      context "with unexpected error StandardError" do
        include_context "with stubbed hmrc-interface submission result StandardError"

        it "logs the exception as information and raises HmrcInterface::RequestError error" do
          allow(Rails.logger).to receive(:info).and_call_original

          expect { call }.to raise_error HmrcInterface::RequestError, /#{described_class} received StandardError/

          expect(Rails.logger)
            .to have_received(:info) do |&block|
                  expect(block.call)
                    .to include(message:/#{described_class} received StandardError/)
                    .and include(backtrace: /.*/)
                    .and include(http_method: "GET")
                    .and include(http_status: nil)
                end
        end
      end

      context "with bad request response" do
        include_context "with stubbed host and bearer token"

        let(:fake_error_body) do
          {
            success: false,
            error_class: "FakeHmrcInterface::BadRequest",
            message: "fake error message",
            backtrace: ["fake error backtrace"],
          }
        end

        before do
           stub_request(:get, %r{#{fake_host}/api/v1/submission/result/.*})
            .to_return(
              status: 400,
              body: fake_error_body.to_json
            )
        end

        it "raises HmrcInterface::RequestUnacceptable error with expected message" do
          expect { call }
            .to raise_error(HmrcInterface::RequestUnacceptable,
                            "URL: #{fake_host}/api/v1/submission/result/fake-hmrc-interface-submission-id, status: 400, details: #{fake_error_body}")
        end
      end

      context "with internal server error response" do
        include_context "with stubbed host and bearer token"

        let(:fake_error_body) do
          {
            success: false,
            error_class: "FakeHmrcInterface::InternalServerError",
            message: "fake error message",
            backtrace: ["fake error backtrace"],
          }
        end

        before do
          stub_request(:get, %r{#{fake_host}/api/v1/submission/result/.*})
            .to_return(
              status: 503,
              body: fake_error_body.to_json
            )
        end

        it "raises HmrcInterface::RequestUnacceptable error with expected message" do
          expect { call }
            .to raise_error(HmrcInterface::RequestUnacceptable,
                            "URL: #{fake_host}/api/v1/submission/result/fake-hmrc-interface-submission-id, status: 503, details: #{fake_error_body}")
        end
      end

      context "with internal server error response and malformed JSON" do
        include_context "with stubbed host and bearer token"

        let(:malformed_json_error_body) { "something went wrong!!" }

        before do
          stub_request(:get, %r{#{fake_host}/api/v1/submission/result/.*})
            .to_return(
              status: 503,
              body: malformed_json_error_body
            )
        end

        it "raises HmrcInterface::RequestUnacceptable error with expected message" do
          expect { call }
            .to raise_error(HmrcInterface::RequestUnacceptable,
                            "URL: #{fake_host}/api/v1/submission/result/fake-hmrc-interface-submission-id, status: 503, details: #{malformed_json_error_body}")
        end
      end
    end
  end

  describe ".call" do
    subject(:call) { described_class.call(client, submission_id) }

    include_context "with stubbed hmrc-interface result completed"

    it "returns expected parsed JSON response" do
      file = file_fixture("results/hmrc_interface_successful_result_response_body.json")
      json = file.read
      parsed_json = JSON.parse(json, symbolize_names: true)

      expect(call).to match(parsed_json)
    end
  end
end
