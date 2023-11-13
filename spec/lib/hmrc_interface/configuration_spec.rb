require "rails_helper"

RSpec.describe HmrcInterface::Configuration do
  subject(:instance) { described_class.new }

  describe '#host' do
    subject(:host) { instance.host }

    it 'defaults to nil' do
      expect(host).to be_nil
    end
  end

  describe '#host=' do
    let(:host) { 'https://mycustom-laa-hmrc-interface-env' }

    before { instance.host = host }

    it 'assigns a non-default host' do
      expect(instance.host).to eql host
    end
  end

  describe '#scopes' do
    subject(:scopes) { instance.scopes }

    context "when non supplied" do
      it { is_expected.to be_nil }
    end

    context "when array supplied" do
      before { instance.scopes = %w[foo bar] }

      it { is_expected.to eql("foo,bar") }
    end
  end

  describe '#scopes=' do
    context "when array of strings supplied" do
      let(:scopes) { %w[use_case_one use_case_two] }

      it 'does not raise any error and stores the array' do
        expect { instance.scopes = scopes }.not_to raise_error
        expect(instance.scopes).to eql("use_case_one,use_case_two")
      end
    end

    context "when array of symbols supplied" do
      let(:scopes) { %i[use_case_one use_case_two] }

      it 'does not raise any error and stores the array' do
        expect { instance.scopes = scopes }.not_to raise_error
        expect(instance.scopes).to eql("use_case_one,use_case_two")
      end
    end

    context "when string supplied" do
      let(:scopes) { "use_case_one,use_case_two" }

      it 'raises Error::ConfigurationError' do
        expect { instance.scopes = scopes }
          .to raise_error(HmrcInterface::Error::ConfigurationError, "scopes must be provider as an array")
      end
    end
  end

  describe '#headers' do
    subject(:headers) { instance.headers }

    it 'defaults to adding a custom User-Agent' do
      expect(headers).to include('User-Agent' => "laa-hmrc-interface-client/#{described_class::VERSION}")
    end
  end

  describe '#headers=' do
    before { instance.headers = headers }

    context "with non-user-agent headers added" do
      let(:headers) { { 'Accept' => 'application/json' } }

      it 'appends the header' do
        expect(instance.headers).to include(headers)
        expect(instance.headers).to include('User-Agent' => "laa-hmrc-interface-client/#{described_class::VERSION}")
      end
    end

    context "with user-agent headers added" do
      let(:headers) { { 'User-Agent' => 'my-own-user-agent', 'Accept' => 'application/xml' } }

      it 'overwrites the existing headers' do
        expect(instance.headers).to include('Accept' => 'application/xml')
        expect(instance.headers).to include('User-Agent' => 'my-own-user-agent')
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

      let(:rails) { class_double(Rails) }
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
    context "with logger that responds to expected methods" do
      let(:logger) { Logger.new($stdout) }

      it "sets logger without errors" do
        expect { instance.logger = logger }.not_to raise_error
        expect(instance.logger).to be logger
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

      it "raises HmrcInterface::Error::ConfigurationError with expected message" do
        expect { instance.logger = logger }
          .to raise_error HmrcInterface::Error::ConfigurationError,
                            "configured logger must respond to info, warn, error, fatal, debug"
      end
    end
  end

  describe "#test_mode?" do
    subject(:call) { instance.test_mode? }

    context "when test_mode not set in config" do
      it { is_expected.to be false }
    end

    context "when test_mode set to \"rubbishg\" in config" do
      before { instance.test_mode = 'not-true-string' }

      it { is_expected.to be false }
    end

    context "when test_mode set to string \"true\" in config" do
      before { instance.test_mode = "true" }

      it { is_expected.to be true }
    end

    context "when test_mode set to boolean true in config" do
      before { instance.test_mode = true }

      it { is_expected.to be true }
    end
  end
end
