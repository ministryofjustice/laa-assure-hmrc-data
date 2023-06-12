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
    subject(:data) { instance.data }

    context "with symbols for keys" do
      let(:result) { { data: [ { use_case: "use_case_one" } ] } }

      it "returns the hash value for data with indifferent access" do
        expect(data).to be_an Array
        expect(data).to eql([{ "use_case" => "use_case_one" }])
        expect(data[0][:use_case]).to eql("use_case_one")
      end
    end

    context "with strings for keys" do
      let(:result) { { "data" => [ { "use_case" => "use_case_one" } ] } }

      it "returns the hash value for data with indifferent access" do
        expect(data).to be_an Array
        expect(data).to eql([{ "use_case" => "use_case_one" }])
        expect(data[0]["use_case"]).to eql("use_case_one")
      end
    end

    context "with no data key" do
      let(:result) { { not_this: [ { "use_case" => "use_case_one" } ] } }

      it { expect(data).to be_nil }
    end
  end

  describe "#error" do
    subject(:error) { instance.error }

    context "when error exists" do
      let(:result) do
        {
          data: [
            { use_case: "whatever" },
            { error: "foobar" } ]
        }
      end

      it "returns the string value for error" do
        expect(error).to eql("foobar")
      end
    end

    context "when error does not exist" do
      let(:result) { { data: [ { foo: "bar" } ] } }

      it { expect(error).to be_nil }
    end

    context "with no data key" do
      let(:result) { { foo: [ { bar: "baz" } ] } }

      it { expect(error).to be_nil }
    end
  end

  describe "#tax_credit_annual_award_amount" do
    subject(:tax_credit_annual_award_amount) { instance.tax_credit_annual_award_amount }

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
        expect(tax_credit_annual_award_amount).to be 9075.96
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
        expect(tax_credit_annual_award_amount).to be 8075.96
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

      it { expect(tax_credit_annual_award_amount).to be_nil }
    end

    context "with no data key" do
      let(:result) { { foo: [ { bar: "baz" } ] } }

      it { expect(tax_credit_annual_award_amount).to be_nil }
    end
  end

  describe "#clients_income_from_employment" do
    subject(:clients_income_from_employment) { instance.clients_income_from_employment }

    context "when multiple income exists" do
      let(:result) do
        {
          "data" => [
            { "use_case" => "use_case_one" },
            {
              "income/paye/paye" => {
                "income" => [
                  {
                    "grossEarningsForNics" => {
                      "inPayPeriod1" => 433
                    },
                  },
                  {
                    "grossEarningsForNics" => {
                      "inPayPeriod1" => 525
                    },
                  }
                ]
              }
            }
          ]
        }
      end

      it "returns the sum of all grossEarningsForNics#inPayPeriod1 values" do
        expect(clients_income_from_employment).to be 958
      end
    end

    context "when single income exists" do
      let(:result) do
        {
          "data" => [
            { "use_case" => "use_case_one" },
            {
              "income/paye/paye" => {
                "income" => [
                  {
                    "grossEarningsForNics" => {
                      "inPayPeriod1" => 433
                    },
                  },
                ]
              }
            }
          ]
        }
      end

      it "returns the single grossEarningsForNics#inPayPeriod1 value" do
        expect(clients_income_from_employment).to be 433
      end
    end

    context "when no income exists" do
      let(:result) do
        {
          "data" => [
            { "use_case" => "use_case_one" },
            {
              "income/paye/paye" => {
                "income" => []
              }
            }
          ]
        }
      end

      it { expect(clients_income_from_employment).to be_zero }
    end

    context "when one is nil and one not" do
      let(:result) do
        {
          "data" => [
            { "use_case" => "use_case_one" },
            {
              "income/paye/paye" => {
                "income" => [
                  {
                    "grossEarningsForNics" => {
                      "inPayPeriod1" => 333
                    },
                  },
                  {
                    "grossEarningsForNics" => {
                    },
                  },
                ]
              }
            }
          ]
        }
      end

      it "returns the single valid grossEarningsForNics#inPayPeriod1 value" do
        expect(clients_income_from_employment).to be 333
      end
    end

    context "with no data key" do
      let(:result) { { foo: [ { bar: "baz" } ] } }

      it { expect(clients_income_from_employment).to be_nil }
    end
  end
end
