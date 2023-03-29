require 'rails_helper'

RSpec.describe BulkSubmission, type: :model do
  let(:instance) { described_class.create!(user:) }

  describe "#user" do
    subject { instance.user }

    let(:user) { User.create!(email: "test.user@example.com") }

    it { is_expected.to eql user }

    context "when user is destroyed" do
      it "nullifies the user_id but does not destroy the bulk submission" do
        expect { user.destroy! }.to change { instance.reload.user }.from(user).to(nil)
      end
    end
  end
end
