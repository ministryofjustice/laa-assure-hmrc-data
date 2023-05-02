require "rails_helper"

RSpec.describe HmrcInterface::Configuration do
  subject(:configuration) { described_class.new }

  describe '#host' do
    subject(:host) { described_class.new.host }

    it 'defaults to nil' do
      expect(host).to be_nil
    end
  end

  describe '#host=' do
    let(:config) { described_class.new }
    let(:host) { 'https://mycustom-laa-hmrc-interface-env' }

    before { config.host = host }

    it 'assigns a non-default host' do
      expect(config.host).to eql host
    end
  end

  describe '#headers' do
    subject(:headers) { described_class.new.headers }

    it 'defaults to adding a custom User-Agent' do
      expect(headers).to include('User-Agent' => "laa-hmrc-interface-client/#{described_class::VERSION}")
    end
  end

  describe '#headers=' do
    let(:config) { described_class.new }

    before { config.headers = headers }

    context "with non-user-agent headers added" do
      let(:headers) { { 'Accept' => 'application/json' } }

      it 'appends the header' do
        expect(config.headers).to include(headers)
        expect(config.headers).to include('User-Agent' => "laa-hmrc-interface-client/#{described_class::VERSION}")
      end
    end

    context "with user-agent headers added" do
      let(:headers) { { 'User-Agent' => 'my-own-user-agent', 'Accept' => 'application/xml' } }

      it 'overwrites the existing headers' do
        expect(config.headers).to include('Accept' => 'application/xml')
        expect(config.headers).to include('User-Agent' => 'my-own-user-agent')
      end
    end
  end

  describe "#test_mode?" do
    subject(:call) { config.test_mode? }

    let(:config) { described_class.new }

    context "when test_mode not set in config" do
      it { is_expected.to be false }
    end

    context "when test_mode set to \"rubbishg\" in config" do
      before { config.test_mode = 'not-true-string' }

      it { is_expected.to be false }
    end

    context "when test_mode set to string \"true\" in config" do
      before { config.test_mode = "true" }

      it { is_expected.to be true }
    end

    context "when test_mode set to boolean true in config" do
      before { config.test_mode = true }

      it { is_expected.to be true }
    end
  end
end
