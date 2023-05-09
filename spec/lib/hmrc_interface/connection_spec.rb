require "rails_helper"

RSpec.describe HmrcInterface::Connection do
  subject(:instance) { described_class.new(client) }

  let(:client) { HmrcInterface.client }

  describe '#configuration' do
    subject(:configuration) { client.configuration }

    include_context "with stubbed host and bearer token"

    it "is delegated to memoized HmrcInterface.configuration" do
      expect(configuration).to eql(HmrcInterface.configuration)
    end
  end

  describe '#connection' do
    subject(:connection) { instance.connection }

    include_context "with stubbed host and bearer token"

    it 'is a faraday connection instance' do
      expect(connection).to be_instance_of(Faraday::Connection)
    end

    it 'has headers from configuration and client merged' do
      expect(connection.headers)
        .to include({ "User-Agent"=>"laa-hmrc-interface-client/0.0.1",
                      "Content-Type"=>"application/json",
                      "Accept"=>"application/json",
                      "Authorization"=>"Bearer test-bearer-token"})
    end

    it 'has host from configuration' do
      expect(connection.build_url)
        .to eql URI.parse("https://fake-laa-hmrc-interface.service.justice.gov.uk/")
    end
  end

  describe "#post" do
    it "is delegated to connection instance" do
      allow(instance.connection).to receive(:post)
      instance.post
      expect(instance.connection).to have_received(:post)
     end
  end
end
