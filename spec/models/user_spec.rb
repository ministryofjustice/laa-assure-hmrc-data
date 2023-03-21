require "rails_helper"

RSpec.describe User, type: :model do
  it { is_expected.to respond_to(:email, :first_name, :last_name) }

  describe "#email" do
    let(:email) { "Jo.Example@example.com" }
    let(:provider) { "azure_ad" }
    let(:user) { described_class.create!(email:, provider: "azure_ad") }

    before { user }

    it "downcases the email automatically" do
      expect(user.email).to eq email.downcase
    end

    it "is case insensitive when queried" do
      query_email = email
      expect(described_class.find_by(email: query_email).email).to eq email.downcase
    end

    it "has case insensitive uniqueness enforced by the db" do
      expect { described_class.create!(email: email.downcase, provider: "azure_ad") }.to(
        raise_error(ActiveRecord::RecordNotUnique,
                    /Key \(email\)=\(jo.example@example.com\) already exists/)
      )
    end
  end

  describe "#full_name" do
    subject { instance.full_name }

    let(:instance) { described_class.new(first_name: "Jim", last_name: "BOB  ") }

    it { is_expected.to eql("Jim BOB") }
  end
end
