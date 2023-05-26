require "rails_helper"

RSpec.describe BulkSubmissionCsvParser do
  let(:content) do
    <<~CSV
      start_date, end_date, first_name, last_name, date_of_birth, nino
      2023-01-01, 2023-03-01, Jim, Bob, 2001-01-01, JA123456D
      2022-01-01, 2022-03-01, John, Boy, 2002-01-01, JA654321D
    CSV
  end

  describe "#call" do
    subject(:call) { described_class.new(content).call }

    context "with expected csv content" do
      let(:content) do
        <<~CSV
          period_start_date, period_end_date, first_name, last_name, date_of_birth, nino
          2023-01-01, 2023-03-31, Jim, Bob, 2001-01-01, JA123456D
          2022-01-01, 2022-03-31, John, Boy, 2002-01-01, JA654321D
        CSV
      end

      it "returns array of objects with expected attributes values" do
        expect(call).to match_array([
          have_attributes(
            period_start_date: "2023-01-01",
            period_start_at: Date.parse("2023-01-01"),
            period_end_date: "2023-03-31",
            period_end_at: Date.parse("2023-03-31"),
            first_name: "Jim",
            last_name: "Bob",
            date_of_birth: "2001-01-01",
            dob: Date.parse("2001-01-01"),
            nino: "JA123456D"
          ),
          have_attributes(
            period_start_date: "2022-01-01",
            period_start_at: Date.parse("2022-01-01"),
            period_end_date: "2022-03-31",
            period_end_at: Date.parse("2022-03-31"),
            first_name: "John",
            last_name: "Boy",
            date_of_birth: "2002-01-01",
            dob: Date.parse("2002-01-01"),
            nino: "JA654321D"
          ),
        ])
      end
    end

    context "with csv header in different order" do
      let(:content) do
        <<~CSV
          nino, period_start_date, period_end_date, first_name, last_name, date_of_birth
          JA123456D, 2023-01-01, 2023-03-31, Jim, Bob, 2001-01-01
          JA654321D, 2022-01-01, 2022-03-31, John, Boy, 2002-01-01
        CSV
      end

      it { expect { call }.not_to raise_error }
    end

    context "with missing csv header and one row" do
      let(:content) do
        <<~CSV
          2023-01-01, 2023-03-01, Jim, Bob, 2001-01-01, JA123456D
        CSV
      end

      it { expect { call }.to raise_error BulkSubmissionCsvParser::InvalidHeader, /invalid or missing headers/ }
    end

    context "with mistaken csv header and multiple rows" do
      let(:content) do
        <<~CSV
          2022-01-01, 2022-03-01, John, Boy, 2002-01-01, JA654321D
          2023-01-01, 2023-03-01, Jim, Bob, 2001-01-01, JA123456D
        CSV
      end

      it { expect { call }.to raise_error BulkSubmissionCsvParser::InvalidHeader, /invalid or missing headers/ }
    end

    context "with invalid csv header content" do
      let(:content) do
        <<~CSV
          starting_at_date, end_date, first_name, last_name, date_of_birth, nino
        CSV
      end

      it { expect { call }.to raise_error BulkSubmissionCsvParser::InvalidHeader, /invalid or missing headers/ }
    end

    context "with no row data" do
      let(:content) do
        <<~CSV
          period_start_date, period_end_date, first_name, last_name, date_of_birth, nino
        CSV
      end

      it { expect { call }.to raise_error BulkSubmissionCsvParser::NoDataFound, /no data found/ }
    end
  end

  describe ".call" do
    subject(:call) { described_class.call(content) }

    let(:instance) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:call)
    end

    it "sends :call message to instance" do
      call
      expect(described_class).to have_received(:new).with(content)
      expect(instance).to have_received(:call)
    end
  end

  describe "#record_struct" do
    subject(:record_struct) { described_class.new(content).record_struct }

    it "defaults to SubmissionRecord" do
      expect(record_struct).to be SubmissionRecord
    end

    it { is_expected.to respond_to(:members) }

    it "can be instantiated with expected attributes and respond to them plus others" do
      args = { period_start_date: '', period_end_date: '',
               first_name: '', last_name: '',
               date_of_birth: '', nino: '' }

      instance = record_struct.new(**args)
      expect(instance).to be_kind_of(Struct)
      expect(instance).to respond_to(*args.keys)
      expect(instance).to respond_to(:period_start_at, :period_end_at, :dob)
    end
  end
end
