require 'rails_helper'

RSpec.describe User, type: :model do
  it { is_expected.to respond_to(:email, :first_name, :last_name) }

  describe '#email' do
    let(:email) { 'Jo.Example@example.com' }
    let(:user) { described_class.create!(email:) }

    before { user }

    it 'preserves the case it was created with' do
      expect(user.email).to eq email
    end

    it 'is case insensitive when queried' do
      query_email = email.dup.downcase
      expect(described_class.find_by(email: query_email).email).to eq email
    end

    it 'has case insensitive uniqueness enforced by the db' do
      expect { described_class.create!(email: email.downcase) }.to(
        raise_error(ActiveRecord::RecordNotUnique,
                    /Key \(email\)=\(jo.example@example.com\) already exists/)
      )
    end
  end
end
