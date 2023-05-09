RSpec.shared_context "with stubbed host" do
  let(:fake_host) { "https://fake-laa-hmrc-interface.service.justice.gov.uk" }

  before { allow(HmrcInterface.configuration).to receive(:host).and_return(fake_host) }
end

RSpec.shared_context "with nil access token" do
  before do
    # remove @access_token to ensure a new oauth token request is made, otherwise previous
    # calls in tests could mean the token exists already and has not expired, causing
    # the oauth/token endpoint to not be hit, resulting in test failure or flickers if oauth/token
    # end point hitting is expected by the test :(
    client.instance_variable_set(:@access_token, nil)
  end
end

RSpec.shared_context "with stubbed host and bearer token" do
  include_context "with stubbed host"

  before do
    stub_request(:post, %r{#{fake_host}/oauth/token})
      .to_return(
        status: 200,
        body: '{"access_token":"test-bearer-token","token_type":"Bearer","expires_in":7200,"created_at":1582809000}',
        headers: { "Content-Type" => "application/json; charset=utf-8" },
      )
  end
end

RSpec.shared_context "with stubbed hmrc-interface submission success" do
  include_context "with stubbed host and bearer token"

  before do
    stub_request(:post, %r{#{fake_host}/api/v1/submission/create/.*})
      .to_return(
        status: 202,
        body: %({"id":"fake-hmrc-interface-submission-id","_links":[{"href":"#{fake_host}/api/v1/submission/status/fake-hmrc-interface-submission-id"}]}),
        headers: { "Content-Type" => "application/json; charset=utf-8" },
      )
  end
end

RSpec.shared_context "with stubbed hmrc-interface result completed" do
  include_context "with stubbed host and bearer token"

  before do
    stub_request(:get, %r{#{fake_host}/api/v1/submission/result/.*})
      .to_return(
        status: 200,
        body: file_fixture("hmrc_interface_successful_result_response_body.json").read,
        headers: { "Content-Type" => "application/json; charset=utf-8" },
      )
  end
end

RSpec.shared_context "with stubbed hmrc-interface result in_progress" do
  include_context "with stubbed host and bearer token"

  before do
    stub_request(:get, %r{#{fake_host}/api/v1/submission/result/.*})
      .to_return(
        status: 200,
        body: file_fixture("hmrc_interface_successful_result_response_body.json").read,
        headers: { "Content-Type" => "application/json; charset=utf-8" },
      )
  end
end

RSpec.shared_context "with stubbed hmrc-interface submission StandardError" do
  include_context "with stubbed host and bearer token"

  before do
    stub_request(:post, %r{#{fake_host}/api/v1/submission/create/.*})
      .to_raise(StandardError)
  end
end

RSpec.shared_context "with stubbed hmrc-interface submission result StandardError" do
  include_context "with stubbed host and bearer token"

  before do
    stub_request(:get, %r{#{fake_host}/api/v1/submission/result/.*})
      .to_raise(StandardError)
  end
end
