require "rails_helper"

RSpec.describe HmrcInterfaceResultable do
  let(:instance) { test_class.new }

  let(:test_class) do
    Class.new.tap do |klass|
      klass.include(described_class)

      klass.attr_accessor :hmrc_interface_result
    end
  end

  let(:result) { {} }

  before do
    allow(instance).to receive(:hmrc_interface_result).and_return(result)
  end

  it 'includes the expected methods' do
    expect(instance)
      .to respond_to(:data,
                     :error,
                     :tax_credit_annual_award_amount)
  end

  describe "#data" do
    context "with symbols for keys" do
      let(:result) { { data: [ { use_case: "use_case_one" } ] } }

      it "returns the hash value for data with indifferent access" do
        expect(instance.data).to be_an Array
        expect(instance.data).to eql([{ "use_case" => "use_case_one" }])
        expect(instance.data[0][:use_case]).to eql("use_case_one")
      end
    end

    context "with strings for keys" do
      let(:result) { { "data" => [ { "use_case" => "use_case_one" } ] } }

      it "returns the hash value for data with indifferent access" do
        expect(instance.data).to be_an Array
        expect(instance.data).to eql([{ "use_case" => "use_case_one" }])
        expect(instance.data[0]["use_case"]).to eql("use_case_one")
      end
    end

    context "with no data key" do
      let(:result) { { not_this: [ { "use_case" => "use_case_one" } ] } }

      it { expect(instance.data).to be_nil }
    end
  end

  describe "#error" do
    context "when error exists" do
      let(:result) do
        {
          data: [
            { use_case: "whatever" },
            { error: "foobar" } ]
        }
      end

      it "returns the string value for error" do
        expect(instance.error).to eql("foobar")
      end
    end

    context "when error does not exist" do
      let(:result) { { data: [ { foo: "bar" } ] } }

      it { expect(instance.error).to be_nil }
    end

    context "with no data key" do
      let(:result) { { foo: [ { bar: "baz" } ] } }

      it { expect(instance.error).to be_nil }
    end
  end

  describe "#tax_credit_annual_award_amount" do
    context "when working and child tax credits exist" do
      let(:result) do
         {
          "data" => [
            { "use_case" => "use_case_one" },
            { "benefits_and_credits/working_tax_credit/applications"=>
               [{ "awards"=>
                  [{ "payments"=>[],
                     "totalEntitlement"=>8075.96 },
                   { "payments"=>[],
                     "totalEntitlement"=>8008.07 }] }] },
            { "benefits_and_credits/child_tax_credit/applications"=>
               [{ "awards"=>
                  [{ "payments"=>[],
                     "totalEntitlement"=>9075.96 },
                   { "payments"=>[],
                     "totalEntitlement"=>9008.07 }] }] }
          ]
        }
      end

      it "returns the decimal value for the first child_tax_credit award" do
        expect(instance.tax_credit_annual_award_amount).to be 9075.96
      end
    end

    context "when working tax credits exist (only)" do
      let(:result) do
         {
          "data" => [
            { "use_case" => "use_case_one" },
            { "benefits_and_credits/working_tax_credit/applications"=>
               [{ "awards"=>
                  [{ "payments"=>[],
                     "totalEntitlement"=>8075.96 },
                   { "payments"=>[],
                    "totalEntitlement"=>8008.07 }] }] }
          ]
        }
      end

      it "returns the decimal value for the first working_tax_credit award" do
        expect(instance.tax_credit_annual_award_amount).to be 8075.96
      end
    end

    context "when no working or tax credits exist" do
      let(:result) do
         {
          "data" => [
            { "use_case" => "use_case_one" },
            { "benefits_and_credits/working_tax_credit/applications" => [] },
            { "benefits_and_credits/child_tax_credit/applications" => [] }
          ]
        }
      end

      it { expect(instance.tax_credit_annual_award_amount).to be_nil }
    end

    context "with no data key" do
      let(:result) { { foo: [ { bar: "baz" } ] } }

      it { expect(instance.tax_credit_annual_award_amount).to be_nil }
    end
  end
end
