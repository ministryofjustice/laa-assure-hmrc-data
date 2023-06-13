require "rails_helper"

RSpec.describe PurgeSensitiveDataWorker, type: :worker do
  describe ".perform_async" do
    subject(:perform_async) { described_class.perform_async }

    it "enqueues 1 job with expected options" do
      expect { perform_async }
        .to change(described_class, :jobs)
          .from([])
          .to(
              [
                hash_including(
                  "retry" => true,
                  "queue" => "default",
                  "args" => [],
                  "class" => "PurgeSensitiveDataWorker"
                )
              ]
          )
    end
  end

  describe "#perform" do
    subject(:perform) { described_class.new.perform }

    let(:bulk_submission) { create(:bulk_submission, :with_original_file, :with_result_file, expires_at:) }
    let(:submission) do
 create(:submission, :with_completed_use_case_one_hmrc_interface_result, first_name: 'Rosie', last_name: 'Conway', 
nino: 'JC654321A', dob: '1977-03-08'.to_date, bulk_submission:) end
    let(:expires_at) { 1.day.ago.midnight }

    before do
      bulk_submission
      submission
    end

    it_behaves_like "applcation worker logger"

    context "when the bulk submission has expired" do
      it "purges the original file" do
        perform
        bulk_submission.reload
        expect(bulk_submission.original_file.attachment).to be_nil
        expect(bulk_submission.original_file.blob).to be_nil
      end
  
      it "purges the result file" do
        perform
        bulk_submission.reload
        expect(bulk_submission.result_file.attachment).to be_nil
        expect(bulk_submission.result_file.blob).to be_nil
      end

      it "updates the submission record" do
        perform
        submission.reload
        expect(submission).to have_attributes(
          first_name: 'purged',
          last_name: 'purged',
          nino:'AB123456C',
          dob: Date.parse('1970-01-01'),
          hmrc_interface_result: '{}'
        )
      end
    end

    context "when the bulk submission has not expired" do
      let(:expires_at) { Time.zone.tomorrow.midnight }

      it "does not purge the original file" do
        perform
        bulk_submission.reload
        expect(bulk_submission.original_file.attachment).not_to be_nil
        expect(bulk_submission.original_file.blob).not_to be_nil
      end
  
      it "does not purge the result file" do
        perform
        bulk_submission.reload
        expect(bulk_submission.result_file.attachment).not_to be_nil
        expect(bulk_submission.result_file.blob).not_to be_nil
      end

      it "does not update the submission record" do
        perform
        submission.reload
        expect(submission).to have_attributes(
          first_name: 'Rosie',
          last_name: 'Conway',
          nino:'JC654321A',
          dob: Date.parse('1977-03-08'),
          hmrc_interface_result: {"data"=>[{"use_case"=>"use_case_one"}]}
        )
      end
    end

    context "when the bulk submission is purgeable" do
      let(:bulk_submission) do
        create(:bulk_submission, :with_original_file, :with_result_file, expires_at: nil, 
created_at: 1.month.ago.midnight)
      end
    
      it "purges the original file" do
        perform
        bulk_submission.reload
        expect(bulk_submission.original_file.attachment).to be_nil
        expect(bulk_submission.original_file.blob).to be_nil
      end
    
      it "purges the result file" do
        perform
        bulk_submission.reload
        expect(bulk_submission.result_file.attachment).to be_nil
        expect(bulk_submission.result_file.blob).to be_nil
      end
    
      it "updates the submission record" do
        perform
        submission.reload
        expect(submission).to have_attributes(
          first_name: 'purged',
          last_name: 'purged',
          nino:'AB123456C',
          dob: Date.parse('1970-01-01'),
          hmrc_interface_result: '{}'
        )
      end
    end
  end
end
