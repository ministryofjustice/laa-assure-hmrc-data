require "rails_helper"

RSpec.describe HmrcInterface::Request::Submission do
  subject(:instance) { described_class.new(client, use_case, filter) }

  let(:client) { HmrcInterface.client }
  let(:use_case) { submission.use_case }

  let(:filter) do
    {
      nino: submission.nino,
      start_date: submission.period_start_at,
      end_date: submission.period_end_at,
      first_name: submission.first_name,
      last_name: submission.last_name,
      dob: submission.dob,
    }
  end

  let(:submission) { create(:submission, :for_sandbox_applicant) }

  describe "#call" do
    subject(:call) { instance.call }

    context "when a successful response is received" do
      include_context "with stubbed hmrc-interface submission success"
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

      it "submits expected submission create request" do
        call

        expect(
          a_request(
            :post,
            "#{fake_host}/api/v1/submission/create/one"
          ).with(body: '{"filter":{"start_date":"2020-10-01","end_date":"2020-12-31","first_name":"Langley","last_name":"Yorke","dob":"1992-07-22","nino":"MN212451D"}}',
                 headers: { 'Accept'=>'application/json',
                            'Content-Type'=>'application/json',
                            'Accept-Encoding'=>/.*/,
                            'Authorization'=>'Bearer test-bearer-token',
                            'User-Agent'=>'laa-hmrc-interface-client/0.0.1'})
        ).to have_been_made.once
      end

      it "returns expected parsed JSON response" do
        expect(call).to match({ id: "fake-hmrc-interface-submission-id",
                                _links: [{
                                  href: "https://fake-laa-hmrc-interface.service.justice.gov.uk/api/v1/submission/status/fake-hmrc-interface-submission-id"
                                }] })
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
                    .and include(method: "POST")
                    .and include(http_status: nil)
                end
        end
      end
    end

    context "when an error occurs in the submission process" do
      context "with unexpected error StandardError" do
        include_context "with stubbed hmrc-interface submission StandardError"

        it "logs the exception as information and raises HmrcInterface::RequestError error" do
          allow(Rails.logger).to receive(:info).and_call_original

          expect { call }.to raise_error HmrcInterface::RequestError, /#{described_class} received StandardError/

          expect(Rails.logger)
            .to have_received(:info) do |&block|
                  expect(block.call)
                    .to include(message:/#{described_class} received StandardError/)
                    .and include(backtrace: /.*/)
                    .and include(method: "POST")
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
           stub_request(:post, %r{#{fake_host}/api/v1/submission/create/.*})
            .to_return(
              status: 400,
              body: fake_error_body.to_json
            )
        end

        it "raises HmrcInterface::RequestUnacceptable error with expected message" do
          expect { call }
            .to raise_error(HmrcInterface::RequestUnacceptable,
                            "Unacceptable request: URL: #{fake_host}/api/v1/submission/create/one, status: 400, details: #{fake_error_body}")
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
          stub_request(:post, %r{#{fake_host}/api/v1/submission/create/.*})
            .to_return(
              status: 503,
              body: fake_error_body.to_json
            )
        end

        it "raises HmrcInterface::RequestUnacceptable error with expected message" do
          expect { call }
            .to raise_error(HmrcInterface::RequestUnacceptable,
                            "Unacceptable request: URL: #{fake_host}/api/v1/submission/create/one, status: 503, details: #{fake_error_body}")
        end
      end

      context "with internal server error response and malformed JSON" do
        include_context "with stubbed host and bearer token"

        let(:malformed_json_error_body) { "something went wrong!!" }

        before do
          stub_request(:post, %r{#{fake_host}/api/v1/submission/create/.*})
            .to_return(
              status: 503,
              body: malformed_json_error_body
            )
        end

        it "raises HmrcInterface::RequestUnacceptable error with expected message" do
          expect { call }
            .to raise_error(HmrcInterface::RequestUnacceptable,
                            "Unacceptable request: URL: #{fake_host}/api/v1/submission/create/one, status: 503, details: #{malformed_json_error_body}")
        end
      end
    end
  end

  describe ".call" do
    subject(:call) { described_class.call(client, use_case, filter) }

    include_context "with stubbed hmrc-interface submission success"

    it "returns expected parsed JSON response" do
      expect(call).to match({ id: "fake-hmrc-interface-submission-id",
                              _links: [{
                                href: "https://fake-laa-hmrc-interface.service.justice.gov.uk/api/v1/submission/status/fake-hmrc-interface-submission-id"
                              }] })
    end
  end
end

