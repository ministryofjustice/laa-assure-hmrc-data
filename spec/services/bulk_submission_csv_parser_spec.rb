require "rails_helper"

RSpec.describe BulkSubmissionCsvParser do
  let(:content) do
    <<~CSV
      start_date, end_date, first_name, last_name, date_of_birth, nino
      01/01/2023, 01/03/2023, Jim, Bob, 01/01/2001, JA123456D
      01/01/2022, 01/03/2022, John, Boy, 01/01/2002, JA654321D
    CSV
  end

  describe "#call" do
    subject(:call) { described_class.new(content).call }

    context "with \"typical\" csv content" do
      let(:content) do
        <<~CSV
          start_date, end_date, first_name, last_name, date_of_birth, nino
          01/01/2023, 01/03/2023, Jim, Bob, 01/01/2001, JA123456D
          01/01/2022, 01/03/2022, John, Boy, 01/01/2002, JA654321D
        CSV
      end

      it "returns array of objects with expected attributes values" do
        expect(call).to match_array([
          have_attributes(
            start_date: "01/01/2023",
            period_start_at: Date.parse("01/01/2023"),
            end_date: "01/03/2023",
            period_end_at: Date.parse("01/03/2023"),
            first_name: "Jim",
            last_name: "Bob",
            date_of_birth: "01/01/2001",
            dob: Date.parse("01/01/2001"),
            nino: "JA123456D"
          ),
          have_attributes(
            start_date: "01/01/2022",
            period_start_at: Date.parse("01/01/2022"),
            end_date: "01/03/2022",
            period_end_at: Date.parse("01/03/2022"),
            first_name: "John",
            last_name: "Boy",
            date_of_birth: "01/01/2002",
            dob: Date.parse("01/01/2002"),
            nino: "JA654321D"
          ),
        ])
      end
    end

    context "with csv header in different order" do
      let(:content) do
        <<~CSV
          nino, start_date, end_date, first_name, last_name, date_of_birth
          JA123456D, 01/01/2023, 01/03/2023, Jim, Bob, 01/01/2001
          JA654321D, 01/01/2022, 01/03/2022, John, Boy, 01/01/2002
        CSV
      end

      it { expect { call }.not_to raise_error }
    end

    context "with missing csv header and one row" do
      let(:content) do
        <<~CSV
          01/01/2023, 01/03/2023, Jim, Bob, 01/01/2001, JA123456D
        CSV
      end

      it { expect { call }.to raise_error BulkSubmissionCsvParser::InvalidHeader, /invalid or missing headers/ }
    end

    context "with mistaken csv header and multiple rows" do
      let(:content) do
        <<~CSV
          01/01/2022, 01/03/2022, John, Boy, 01/01/2002, JA654321D
          01/01/2023, 01/03/2023, Jim, Bob, 01/01/2001, JA123456D
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
          start_date, end_date, first_name, last_name, date_of_birth, nino
        CSV
      end

      it { expect { call }.to raise_error BulkSubmissionCsvParser::NoDataFound, /no data found/ }
    end
  end

  describe ".call" do
    subject(:call) { described_class.call(content) }

    let(:instance) { instance_double(described_class) }

    it "sends :call message to instance" do
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:call)

       described_class.call(content)

      expect(described_class).to have_received(:new).with(content)
      expect(instance).to have_received(:call)
    end
  end
end
