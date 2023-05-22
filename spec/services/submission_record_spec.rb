require "rails_helper"

RSpec.describe SubmissionRecord do
  subject(:instance) { described_class.new(**row) }

  let(:row) do
    {
      period_start_date: "2023-01-01",
      period_end_date: "2023-03-31",
      first_name: "Jim",
      last_name: "Bob",
      date_of_birth: "2001-01-01",
      nino: "JA123456D",
    }
  end

  it "has required attributes for a submission record from a csv" do
    expect(instance)
      .to respond_to(:period_start_date,
                     :period_end_date,
                     :first_name,
                     :last_name,
                     :date_of_birth,
                     :nino)
  end

  describe "#members" do
    subject(:members) { described_class.new.members }

    it "returns list of attributes" do
      expect(members).to include(:period_start_date,
                     :period_end_date,
                     :first_name,
                     :last_name,
                     :date_of_birth,
                     :nino,
                     )
    end
  end

  describe "#period_start_at" do
    subject(:period_start_at) { instance.period_start_at }

    it { is_expected.to be_a(Date) }
  end

  describe "#period_end_at" do
    subject(:period_end_at) { instance.period_end_at }

    it { is_expected.to be_a(Date) }
  end

  describe "#dob" do
    subject(:dob) { instance.dob }

    it { is_expected.to be_a(Date) }
  end
end
