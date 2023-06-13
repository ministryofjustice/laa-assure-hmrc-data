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
                      "inPayPeriod1" => 111.11
                    },
                  },
                  {
                    "grossEarningsForNics" => {
                      "inPayPeriod1" => 222.22
                    },
                  }
                ]
              }
            }
          ]
        }
      end

      it "returns the sum of all grossEarningsForNics#inPayPeriod1 values" do
        expect(clients_income_from_employment).to be 333.33
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
                      "inPayPeriod1" => 444.44
                    },
                  },
                ]
              }
            }
          ]
        }
      end

      it "returns the single grossEarningsForNics#inPayPeriod1 value" do
        expect(clients_income_from_employment).to be 444.44
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
                      "inPayPeriod1" => 333.33
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
        expect(clients_income_from_employment).to be 333.33
      end
    end

    context "with no data key" do
      let(:result) { { foo: [ { bar: "baz" } ] } }

      it { expect(clients_income_from_employment).to be_nil }
    end
  end

  describe "#clients_ni_contributions_from_employment" do
    subject(:clients_ni_contributions_from_employment) { instance.clients_ni_contributions_from_employment }

    context "when multiple income exists" do
      let(:result) do
        {
          "data" => [
           { "income/paye/paye" => {
                "income" => [
                  {
                    "employeeNics" => {
                      "inPayPeriod1" => 222.22
                    },
                  },
                  { "employeeNics" => {
                      "inPayPeriod1" => 444.44
                    },
                  },
                ]
              }
            }
          ]
        }
      end

      it "returns the sum of all employeeNics#inPayPeriod1 values" do
        expect(clients_ni_contributions_from_employment).to be 666.66
      end
    end

    context "when single income exists" do
      let(:result) do
        {
          "data" => [
           { "income/paye/paye" => {
                "income" => [
                  {
                    "employeeNics" => {
                      "inPayPeriod1" => 222.22
                    },
                  },
                ]
              }
            }
          ]
        }
      end

      it "returns the single employeeNics#inPayPeriod1 value" do
        expect(clients_ni_contributions_from_employment).to be 222.22
      end
    end

    context "when no income exists" do
      let(:result) do
        {
          "data" => [
            {
              "income/paye/paye" => {
                "income" => []
              }
            }
          ]
        }
      end

      it { expect(clients_ni_contributions_from_employment).to be_zero }
    end

    # NOTE: real data seen that reflects this
    context "when one income entry has employeeNics and one does not" do
      let(:result) do
        {
          "data" => [
           { "income/paye/paye" => {
                "income" => [
                  { "employeeNics" => {
                      "inPayPeriod1" => 444.44
                    },
                  },
                  {
                  },
                ]
              }
            }
          ]
        }
      end

      it "returns the single valid employeeNics#inPayPeriod1 value" do
        expect(clients_ni_contributions_from_employment).to be 444.44
      end
    end

    context "with no data key" do
      let(:result) { { foo: [ { bar: "baz" } ] } }

      it { expect(clients_ni_contributions_from_employment).to be_nil }
    end
  end

  describe "#start_and_end_dates_for_employments" do
    subject(:start_and_end_dates_for_employments) { instance.start_and_end_dates_for_employments }

    context "when multiple employments exist" do
      let(:result) do
        {
          "data" => [
            { "use_case" => "use_case_one" },
            {
              "employments/paye/employments": [
                {
                  "endDate": "2099-12-31",
                  "startDate": "2023-01-26"
                },
                {
                  "endDate": "2022-11-11",
                  "startDate": "2022-09-11"
                }
              ]
            },
          ]
        }
      end

      it "returns a multiline String with \"start-date to end-date\"" do
        expect(start_and_end_dates_for_employments).to eql("2023-01-26 to 2099-12-31\n2022-09-11 to 2022-11-11")
      end
    end

    context "when single employment exists" do
      let(:result) do
        {
          "data" => [
            { "use_case" => "use_case_one" },
            {
              "employments/paye/employments": [
                {
                  "endDate": "2099-12-31",
                  "startDate": "2023-01-26"
                },
              ]
            },
          ]
        }
      end

      it "returns a String with \"start-date to end-date\"" do
        expect(start_and_end_dates_for_employments).to eql("2023-01-26 to 2099-12-31")
      end
    end

    context "when no employments exist" do
      let(:result) do
        {
          "data" => [
            { "use_case" => "use_case_one" },
            {
              "employments/paye/employments" => [
              ]
            },
          ]
        }
      end

      it { expect(start_and_end_dates_for_employments).to be_nil }
    end

    # NOTE: have not seen real data that reflect's it but is useful safeguard
    context "when employments key does not exist" do
      let(:result) do
        {
          "data" => [
            { "use_case" => "use_case_one" },
          ]
        }
      end

      it { expect(start_and_end_dates_for_employments).to be_nil }
    end

    context "with no data key" do
      let(:result) { { foo: [ { bar: "baz" } ] } }

      it { expect(start_and_end_dates_for_employments).to be_nil }
    end
  end

  describe "#most_recent_payment" do
    subject(:most_recent_payment) { instance.most_recent_payment }

    context "when multiple income exists" do
      let(:result) do
        {
          "data" => [
            { "use_case" => "use_case_one" },
            {
              "income/paye/paye" => {
                "income" => [
                  {
                    "paymentDate" => "2022-03-17",
                    "grossEarningsForNics" => {
                      "inPayPeriod1" => 111.11
                    },
                  },
                  {
                    "paymentDate" => "2022-02-20",
                    "grossEarningsForNics" => {
                      "inPayPeriod1" => 222.22
                    },
                  }
                ]
              }
            }
          ]
        }
      end

      it "returns the most recent/top income entry's #paymentDate and grossEarningsForNics#inPayPeriod1 value" do
        expect(most_recent_payment).to eql("2022-03-17: 111.11")
      end
    end

    context "when single income exists" do
      let(:result) do
        {
          "data" => [
           { "income/paye/paye" => {
                "income" => [
                  {
                    "paymentDate" => "2022-03-17",
                    "grossEarningsForNics" => {
                      "inPayPeriod1" => 222.22
                    },
                  },
                ]
              }
            }
          ]
        }
      end

      it "returns the most recent/top income entry's #paymentDate and grossEarningsForNics#inPayPeriod1 value" do
        expect(most_recent_payment).to eql("2022-03-17: 222.22")
      end
    end

    context "when no income exists" do
      let(:result) do
        {
          "data" => [
            {
              "income/paye/paye" => {
                "income" => []
              }
            }
          ]
        }
      end

      it { expect(most_recent_payment).to be_nil }
    end

    # NOTE: have not seen real data that reflect's it but is useful safeguard
    context "when top income entry has no #paymentDate and grossEarningsForNics#inPayPeriod1" do
      let(:result) do
        {
          "data" => [
           { "income/paye/paye" => {
                "income" => [
                  {
                  },
                  {
                    "paymentDate" => "2022-03-17",
                    "grossEarningsForNics" => {
                      "inPayPeriod1" => 555.55
                    },
                  },
                  {
                  },
                ]
              }
            }
          ]
        }
      end

      it "ignores payments where the #paymentDate and grossEarningsForNics#inPayPeriod1 are not available" do
        expect(most_recent_payment).to eql("2022-03-17: 555.55")
      end
    end

    context "with no data key" do
      let(:result) { { foo: [ { bar: "baz" } ] } }

      it { expect(most_recent_payment).to be_nil }
    end
  end
end
