require 'rails_helper'

RSpec.describe BulkSubmission, type: :model do
  let(:instance) { described_class.create!(user:) }

  describe "#user" do
    subject { instance.user }

    let(:user) { create(:user) }

    it { is_expected.to eql(user) }

    context "when user is destroyed" do
      it "nullifies the user_id but does not destroy the bulk submission" do
        expect { user.destroy! }.to change { instance.reload.user }.from(user).to(nil)
      end
    end
  end

  describe "#original_file" do
    subject { instance.original_file }

    let(:user) { create(:user) }
    let(:file_io) { File.open(Rails.root.join('spec/fixtures/files/basic_bulk_submission.csv')) }

    it { is_expected.to be_an_instance_of(ActiveStorage::Attached::One) }

    it "can have a file attached" do
      expect(instance.original_file).not_to be_attached
      instance.original_file.attach(io: file_io, filename: "my_bulk_submission.csv", content_type: 'text/csv')
      expect(instance.original_file).to be_attached
    end
  end
end
