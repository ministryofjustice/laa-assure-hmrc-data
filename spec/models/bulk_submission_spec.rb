require 'rails_helper'

RSpec.describe BulkSubmission, type: :model do
  let(:instance) { create(:bulk_submission, user:) }
  let(:user) { create(:user) }

  describe "#user" do
    subject { instance.user }

    it { is_expected.to eql(user) }

    context "when user is destroyed" do
      it "nullifies the user_id but does not destroy the bulk submission" do
        expect { user.destroy! }.to change { instance.reload.user }.from(user).to(nil)
      end
    end
  end

  describe "#submissions" do
    subject { instance.submissions }

    let(:submission) { create(:submission, bulk_submission: instance) }

    before do
     submission
    end

    it { is_expected.to include(submission) }
  end

  describe "#original_file" do
    subject { instance.original_file }

    let(:file_io) { File.open(Rails.root.join('spec/fixtures/files/basic_bulk_submission.csv')) }

    it { is_expected.to be_an_instance_of(ActiveStorage::Attached::One) }

    it "can have a file attached" do
      expect(instance.original_file).not_to be_attached
      instance.original_file.attach(io: file_io, filename: "my_bulk_submission.csv", content_type: 'text/csv')
      expect(instance.original_file).to be_attached
    end
  end

  describe "#destroy" do
    before do
      create(:submission, bulk_submission: instance)
    end

    it "cascades to submissions" do
      expect { instance.destroy }.to change(Submission, :count).by(-1)
    end
  end
end
