require "rails_helper"

RSpec.describe User, type: :model do
  describe "#email" do
    let(:email) { "Jo.Example@example.com" }
    let(:auth_provider) { "azure_ad" }
    let(:user) { described_class.create!(email:, auth_provider:) }

    before { user }

    it "downcases the email automatically" do
      expect(user.email).to eq email.downcase
    end

    it "is case insensitive when queried" do
      query_email = email
      expect(described_class.find_by(email: query_email).email).to eq email.downcase
    end

    it "has case insensitive uniqueness enforced by the db" do
      expect { described_class.create!(email: email.downcase, auth_provider:) }.to(
        raise_error(ActiveRecord::RecordNotUnique,
                    /Key \(email\)=\(jo.example@example.com\) already exists/)
      )
    end
  end

  describe ".from_omniauth" do
    subject(:call) { described_class.from_omniauth(auth) }

    let(:auth) { MockAzureAdAuthHash::JIM_BOB }

    context "when user exists with auth_subject_uid" do
      before { user }

      let(:user) { described_class.create!(auth_subject_uid: "jim-bob-fake-uid") }

      it "update last_sign_in_at" do
        expect { call }.to change { user.reload.last_sign_in_at }
      end

      it "return the user" do
        expect(call).to eql user
      end
    end

    context "when user exists without auth_subject_uid" do
      before { user }

      let(:user) do
        described_class.create!(email: "jim.bob@example.co.uk",
                                auth_provider: "azure_ad",
                                auth_subject_uid: nil)
      end

      it "updates auth_subject_id, first_name, last_name" do
        expect { call }.to change { user.reload.attributes }
            .from(hash_including("auth_subject_uid" => nil, "first_name" => "", "last_name" => ""))
            .to(hash_including("auth_subject_uid" => "jim-bob-fake-uid", "first_name" => "Jim", "last_name" => "Bob"))
      end

      it "updates last_sign_in_at" do
        expect { call }.to change { user.reload.last_sign_in_at }
      end
    end

    context "when user does not exist" do
      it "return nil" do
        expect(call).to be_nil
      end
    end

  end

  describe "#full_name" do
    subject { instance.full_name }

    let(:instance) { described_class.new(first_name: " Jim", last_name: "BOB  ") }

    it { is_expected.to eql("Jim BOB") }
  end
end
