require "rails_helper"

RSpec.describe HmrcInterface do
  it { is_expected.to respond_to :client, :configuration, :configure, :reset }

  describe ".client" do
    subject(:client) { described_class.client }

    it { is_expected.to be_instance_of(described_class::Client) }
  end

  describe ".configuration" do
    subject(:configuration) { described_class.configuration }

    it { is_expected.to be_instance_of(described_class::Configuration) }

    it 'memoizes the configuration' do
      expect(configuration).to be_equal(described_class.configuration)
    end

    it "aliased to config" do
      expect(described_class.method(:config)).to eql(described_class.method(:configuration))
    end
  end

  describe '.configure' do
    it 'yields a config' do
      expect { |block| described_class.configure(&block) }.to yield_with_args(kind_of(described_class::Configuration))
    end

    it 'returns a configuration' do
      expect(described_class.configure).to be_an_instance_of(described_class::Configuration)
    end

    context 'with configured host' do
      let(:host) { 'https://mycustom-laa-hmrc-interface-env' }

      before do
        described_class.configure do |config|
          config.host = host
        end
      end

      it 'changes the host configuration' do
        expect(described_class.configuration.host).to eql host
      end
    end
  end

  describe '.reset' do
    subject(:reset) { described_class.reset }

    let(:options) do
      {
        "headers"=>{ "User-Agent"=>"laa-hmrc-interface-client/0.0.1" },
        "client_id"=>"my-client-id",
        "client_secret"=>"my-client-secret",
        "host"=>"https://mycustom-laa-hmrc-interface-env"
      }
    end

    let(:reset_options) do
      { "headers"=> { "User-Agent"=>"laa-hmrc-interface-client/0.0.1" } }
    end

    before do
      described_class.configure do |config|
        config.client_id = options["client_id"]
        config.client_secret = options["client_secret"]
        config.host = options["host"]
      end
    end

    it 'resets the configured options' do
      expect { reset }
        .to change { described_class.configuration.as_json.to_h }
        .from(options)
        .to(reset_options)
    end
  end
end
