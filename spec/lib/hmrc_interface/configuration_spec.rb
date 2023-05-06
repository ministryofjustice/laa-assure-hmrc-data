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

  describe "#logger" do
    subject(:logger) { config.logger }

    let(:config) { described_class.new }

    context "with custom logger configured" do
      before { config.logger = custom_logger }

      let(:custom_logger) { logger_klass.new }

      let(:logger_klass) do
        Class.new do
          def info
          end
          def warn
          end
          def error
          end
          def fatal
          end
          def debug
          end
        end
      end

      it "sets logger without errors" do
        expect(config.logger).to be custom_logger
      end
    end

    context "with no logger configured and using rails" do
      before do
        stub_const("Rails", rails)
        allow(rails).to receive(:logger).and_return(rails_logger)
      end

      let(:rails) { class_double("Rails") }
      let(:rails_logger) { Class.new }

      it "defaults to using Rails.logger" do
        expect(logger).to be rails_logger
      end
    end

    context "with no logger configured and not using rails" do
      before do
        allow(Logger).to receive(:new).with($stdout).and_return(ruby_logger)
      end

      let(:ruby_logger) { instance_double(Logger)}

      # rubocop:disable RSpec/LeakyConstantDeclaration
      around do |example|
        TempRails = Object.send(:remove_const, :Rails)
        example.run
      ensure
        Rails = TempRails
        Object.send(:remove_const, :TempRails)
      end
      # rubocop:enable RSpec/LeakyConstantDeclaration

      it "defaults to using ruby standard library Logger" do
        expect(logger).to be ruby_logger
      end
    end
  end

  describe "#logger=" do
    let(:config) { described_class.new }

    context "with logger that responds to expected methods" do
      let(:logger) { Logger.new($stdout) }

      it "sets logger without errors" do
        expect { config.logger = logger }.not_to raise_error
        expect(config.logger).to be logger
      end
    end

    context "with logger that does not respond to all expected methods" do
      let(:logger) { logger_klass.new }

      let(:logger_klass) do
        Class.new do
          def info
          end
        end
      end

      it "raises HmrcInterface::ConfigurationError with expected message" do
        expect { config.logger = logger }
          .to raise_error HmrcInterface::ConfigurationError,
                            "configured logger must respond to info, warn, error, fatal, debug"
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
