require "rails_helper"

RSpec.describe HmrcInterface::Client do
  subject(:client) { described_class.new }

  include_context "with stubbed host and bearer token"

  describe "#configuration" do
    subject(:configuration) { client.configuration }

    it "is delegated to memoized HmrcInterface.configuration" do
      expect(configuration).to eql(HmrcInterface.configuration)
    end
  end

  describe "#host" do
    subject(:host) { client.host }

    it "is delegated to configuration#host" do
      expect(host).to eql("https://fake-laa-hmrc-interface.service.justice.gov.uk")
    end
  end

  describe "#headers" do
    subject(:headers) { client.headers }

    it "includes expected headers" do
      expect(headers)
        .to include("Accept" => "application/json",)
        .and include("Content-Type" => "application/json")
        .and include("Authorization" => "Bearer test-bearer-token")
        .and include("User-Agent" => /laa-hmrc-interface-client\/\d{1}\.\d{1}\.\d{1}$/)
    end
  end

  describe "#access_token" do
    subject(:access_token) { client.access_token }

    it { is_expected.to be_an OAuth2::AccessToken }
    it { is_expected.to respond_to :token }
    it { is_expected.to respond_to :expired? }
    it { expect(access_token.token).to eql "test-bearer-token" }

    it "sends custom user agent in header" do
      access_token
      expect(
        a_request(:post, "https://fake-laa-hmrc-interface.service.justice.gov.uk/oauth/token")
      ).to have_been_made
    end

    context "when retrieving a new token" do
      let(:oauth_client) { instance_double(OAuth2::Client, client_credentials:) }
      let(:client_credentials) { instance_double(OAuth2::Strategy::ClientCredentials, get_token: new_token) }
      let(:new_token) { instance_double(OAuth2::AccessToken, token: 'new-fake-token') }

      before do
        client.instance_variable_set(:@oauth_client, oauth_client)
        allow(oauth_client).to receive(:client_credentials).and_return(client_credentials)
      end

      context "when token nil?" do
        include_context "with nil access token"

        it "retrieves new access_token using client_credentials grant type" do
          expect(access_token).to eq(new_token)
          expect(oauth_client).to have_received(:client_credentials)
          expect(client_credentials).to have_received(:get_token).with(scopes: "use_case_one,use_case_two")
        end
      end

      context "when token expired?" do
        let(:old_token) { instance_double(OAuth2::AccessToken, token: 'old-fake-token', expired?: true) }

        before do
          client.instance_variable_set(:@access_token, old_token)
        end

        it "retrieves new access_token using client_credentials grant type" do
          expect(access_token).to eq(new_token)
          expect(oauth_client).to have_received(:client_credentials)
          expect(client_credentials).to have_received(:get_token).with(scopes: "use_case_one,use_case_two")
        end
      end
    end
  end

  describe "#bearer_token" do
    subject(:bearer_token) { client.bearer_token }

    context "when test_mode not set" do
      before { allow(HmrcInterface.configuration).to receive(:test_mode?).and_return(nil) }

      it "sends custom user agent in header" do
        bearer_token
        expect(
          a_request(:post, "https://fake-laa-hmrc-interface.service.justice.gov.uk/oauth/token")
        ).to have_been_made
      end

      it "generates a new bearer_token" do
        expect(bearer_token).to eq "test-bearer-token"
      end
    end

    context "when test_mode is set" do
      before { allow(HmrcInterface.configuration).to receive(:test_mode?).and_return(true) }

      it "returns a set, fake, bearer_token" do
        expect(bearer_token).to eq "fake-hmrc-interface-bearer-token"
      end
    end
  end
end
