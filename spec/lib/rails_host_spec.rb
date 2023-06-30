require "rails_helper"

RSpec.describe RailsHost do
  around { |example| with_env(environment) { example.run } }

  describe ".env" do
    subject { described_class.env }

    context "when host_env is uat" do
      let(:environment) { "uat" }

      it { is_expected.to eq("uat") }
    end

    context "when host_env is staging" do
      let(:environment) { "staging" }

      it { is_expected.to eq("staging") }
    end

    context "when host_env is production" do
      let(:environment) { "production" }

      it { is_expected.to eq("production") }
    end

    context "when host_env is gibberish" do
      let(:environment) { "gibberish" }

      it { is_expected.to eq("gibberish") }
    end
  end

  describe ".host" do
    context "when host_env is uat" do
      let(:environment) { "uat" }

      it "returns the rails host envirobment name" do
        expect(Rails.host.env).to eq "uat"
      end

      it "returns true for #uat?" do
        expect(Rails.host.uat?).to be true
      end

      it "returns false for #staging?" do
        expect(Rails.host.staging?).to be false
      end

      it "returns false for #production?" do
        expect(Rails.host.production?).to be false
      end
    end

    context "when host_env is staging" do
      let(:environment) { "staging" }

      it "returns the rails environement host name" do
        expect(Rails.host.env).to eq "staging"
      end

      it "returns true for #staging?" do
        expect(Rails.host.staging?).to be true
      end

      it "returns false for #production?" do
        expect(Rails.host.production?).to be false
      end

      it "returns false for #uat?" do
        expect(Rails.host.uat?).to be false
      end
    end

    context "when host_env is production" do
      let(:environment) { "production" }

      it "returns the rails environement host name" do
        expect(Rails.host.env).to eq "production"
      end

      it "returns true for #production?" do
        expect(Rails.host.production?).to be true
      end

      it "returns false for #staging?" do
        expect(Rails.host.staging?).to be false
      end

      it "returns false for #uat?" do
        expect(Rails.host.uat?).to be false
      end
    end

    context "when host environment is not a valid/allowed environment" do
      let(:environment) { "gibberish" }

      it "raises method missing if invalid method name" do
        expect { Rails.host.gibberish? }.to raise_error NoMethodError,
                    /undefined method .gibberish\?/
      end
    end
  end

  describe ".respond_to_missing" do
    let(:environment) { "staging" }

    it "raises error when missing method called using `method`" do
      expect { Rails.host.method(:my_missing_method) }.to raise_error NameError,
                  /undefined method `my_missing_method/
    end
  end
end
