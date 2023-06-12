require 'rails_helper'

RSpec.describe Submission, type: :model do
  let(:instance) { create(:submission) }

  describe "#bulk_submission" do
    subject(:bulk_submission) { instance.bulk_submission }

    it { is_expected.to be_kind_of(BulkSubmission) }
  end

  context "when validating" do
    it "first name must be present" do
      submission = build(:submission, first_name: nil)
      submission.validate

      expect(submission.errors[:first_name]).to include("Provide a first name")
    end

    it "last name must be present" do
      submission = build(:submission, last_name: nil)
      submission.validate

      expect(submission.errors[:last_name]).to include("Provide a last name")
    end

    it "use_case must be present and be one of the acceptable values" do
      submission = build(:submission, use_case: nil)
      submission.validate

      expect(submission.errors[:use_case]).to include("Provide a use case")

      submission = build(:submission, use_case: :three)
      submission.validate

      expect(submission.errors[:use_case]).to include("\"three\" is not a valid use case")
    end

    it "nino (national insurance number) must be present and have a valid format" do
      submission = build(:submission, nino: nil)
      submission.validate

      expect(submission.errors[:nino]).to include("Provide a nino (national insurance number)")

      submission = build(:submission, nino: "JAX12345D")
      submission.validate

      expect(submission.errors[:nino]).to include("\"JAX12345D\" is not a valid national insurance number")
    end

    it "period_start_at can be nil but not in the future" do
      submission = build(:submission, period_start_at: nil)
      submission.validate

      expect(submission).to be_valid

      submission = build(:submission, period_start_at: Date.tomorrow)
      submission.validate

      expect(submission.errors[:period_start_at]).to include("Start date cannot be in the future")
    end

    it "period_end_at can be nil but not in the future" do
      submission = build(:submission, period_end_at: nil)
      submission.validate

      expect(submission).to be_valid

      submission = build(:submission, period_end_at: Date.tomorrow)
      submission.validate

      expect(submission.errors[:period_end_at]).to include("End date cannot be in the future")
    end

    it "period_end_at must be after period_start_at" do
      submission = build(:submission, period_start_at: 1.day.ago, period_end_at: 2.days.ago)
      submission.validate

      expect(submission.errors[:period_start_at]).to include("Start date cannot be after end date")
      expect(submission.errors[:period_end_at]).to include("End date cannot be before Start date")
    end
  end

  it "is status settable" do
    expected_status_methods = ["!", "?"].each_with_object([]) do |c, memo|
      memo << ["pending#{c}", "submitting#{c}", "submitted#{c}",
               "completing#{c}", "created#{c}", "processing#{c}",
               "completed#{c}", "failed#{c}", "exhausted#{c}", "purged#{c}"]
    end

    expect(instance).to respond_to(*expected_status_methods.flatten)
  end
end
