require 'rails_helper'

RSpec.describe BulkSubmissionForm, type: :model do
  let(:instance) { described_class.new(user_id: user.id, status: "pending", uploaded_file: a_file) }
  let(:user) { create(:user) }

  describe "#save" do
    subject(:save) { instance.save }

    context "with a valid file" do
      let(:a_file) { fixture_file_upload('basic_bulk_submission.csv', 'text/csv') }

      it "creates a bulk submission and attaches a file to it" do
        expect { save }.to change(BulkSubmission, :count).by(1)
        expect(instance.bulk_submission.original_file).to be_attached
        expect(instance.errors).to be_empty
      end
    end

    context "with an empty file" do
      let(:a_file) { fixture_file_upload('empty.csv', 'text/csv') }

      it "does not create a bulk_submission and adds errors" do
        expect { save }.not_to change(BulkSubmission, :count)
        expect(instance.bulk_submission).to be_nil
        expect(instance.errors[:uploaded_file]).to include("empty.csv is empty")
      end
    end

    context "with a file that is exactly one mebibyte" do
      before do
        allow(instance).to receive(:file_content).and_return(true)
      end

      let(:a_file) { fixture_file_upload('exactly_one_mebibyte.csv', 'text/csv') }

      it "creates a bulk submission and attaches a file to it" do
        expect { save }.to change(BulkSubmission, :count).by(1)
        expect(instance.bulk_submission.original_file).to be_attached
        expect(instance.errors).to be_empty
      end
    end

    context "with a file that is too big" do
      let(:a_file) { fixture_file_upload('one_byte_too_big.csv', 'text/csv') }

      it "does not create a bulk_submission and adds errors" do
        expect { save }.not_to change(BulkSubmission, :count)
        expect(instance.bulk_submission).to be_nil
        expect(instance.errors[:uploaded_file]).to include("one_byte_too_big.csv is more than 1MB")
      end
    end

    context "with a file whose CHECKED content_type is not acceptable" do
      let(:a_file) { fixture_file_upload('invalid_content_type_png_as_csv.csv') }

      it "does not create a bulk_submission and adds errors" do
        expect { save }.not_to change(BulkSubmission, :count)
        expect(instance.bulk_submission).to be_nil
        expect(instance.errors[:uploaded_file]).to include("invalid_content_type_png_as_csv.csv must be a CSV")
      end
    end

    context "with a file whose DECLARED content_type is not acceptable" do
      let(:a_file) { fixture_file_upload('basic_bulk_submission.csv', 'image/png') }

      it "does not create a bulk_submission and adds errors" do
        expect { save }.not_to change(BulkSubmission, :count)
        expect(instance.bulk_submission).to be_nil
        expect(instance.errors[:uploaded_file]).to include("basic_bulk_submission.csv must be a CSV")
      end
    end

    context "with a file that is too long" do
      let(:a_file) { fixture_file_upload('too_many_rows.csv', 'text/csv') }

      it "does not create a bulk_submission and adds errors" do
        expect { save }.not_to change(BulkSubmission, :count)
        expect(instance.bulk_submission).to be_nil
        expect(instance.errors[:uploaded_file]).to include("too_many_rows.csv has more than 35 records")
      end
    end

    context "with a file with invalid headers" do
      let(:a_file) { fixture_file_upload('invalid_headers.csv', 'text/csv') }

      it "does not create a bulk_submission and adds errors" do
        expect { save }.not_to change(BulkSubmission, :count)
        expect(instance.bulk_submission).to be_nil
        expect(instance.errors[:uploaded_file]).to include("invalid_headers.csv has invalid headers")
      end
    end

    context "with a file with invalid content" do
      let(:a_file) { fixture_file_upload('invalid_content.csv', 'text/csv') }

      it "does not create a bulk_submission and adds errors" do
        expect { save }.not_to change(BulkSubmission, :count)
        expect(instance.bulk_submission).to be_nil
        expect(instance.errors[:uploaded_file]).to include("invalid_content.csv first name missing at row 2")
        .and include("invalid_content.csv last name missing at row 2")
        .and include("invalid_content.csv invalid date of birth at row 2")
        .and include("invalid_content.csv invalid national insurance number at row 2")
        .and include("invalid_content.csv invalid period start date at row 2")
        .and include("invalid_content.csv invalid period end date at row 2")
      end
    end

    context "with a file with an invalid period" do
      let(:a_file) { fixture_file_upload('invalid_period.csv', 'text/csv') }

      it "does not create a bulk_submission and adds errors" do
        expect { save }.not_to change(BulkSubmission, :count)
        expect(instance.bulk_submission).to be_nil
        expect(instance.errors[:uploaded_file])
          .to include("invalid_period.csv period end date earlier than period start date at row 2")
      end
    end

    context "with an unparseable file with empty rows" do
      let(:a_file) { fixture_file_upload('unparseable_file.csv', 'text/csv') }

      it "does not create a bulk_submission and adds errors" do
        expect { save }.not_to change(BulkSubmission, :count)
        expect(instance.bulk_submission).to be_nil
        expect(instance.errors[:uploaded_file])
          .to include("unparseable_file.csv unable to read file")
      end
    end

    context "with a file containing whitespace in headers" do
      let(:a_file) { fixture_file_upload('whitespace.csv', 'text/csv') }

      it "creates a bulk submission and attachs a file to it" do
        expect { save }.to change(BulkSubmission, :count).by(1)
        expect(instance.bulk_submission.original_file).to be_attached
        expect(instance.errors).to be_empty
      end
    end

    context "with a file containing a virus", :scan_with_clamav do
      let(:a_file) { fixture_file_upload('malware.csv', 'text/csv') }

      it "adds error to object" do
        save
        expect(instance.errors[:uploaded_file])
          .to include("malware.csv contains a virus!")
      end

      it "does not persist the bulk_submission" do
        expect { save }.not_to change(BulkSubmission, :count)
      end

      it "record upload attempt in database" do
        expect { save }.to change(MalwareScanResult, :count).by(1)
      end
    end
  end

  describe "#update" do
    subject(:update) do
      instance.uploaded_file = a_file
      instance.update
    end

    before do
      instance.uploaded_file = fixture_file_upload('basic_bulk_submission.csv', 'text/csv')
      instance.save
    end

    let(:instance) { described_class.new(user_id: user.id, status: "pending") }

    context "with a valid file" do
      let(:a_file) { fixture_file_upload('basic_bulk_submission_copy.csv', 'text/csv') }

      it "replaces the original_file on the bulk submission" do
        expect {
          update
        }.to change {
          instance.bulk_submission.original_file.filename.to_s
        }.from('basic_bulk_submission.csv')
         .to('basic_bulk_submission_copy.csv')
      end
    end

    context "with an empty file" do
      let(:a_file) { fixture_file_upload('empty.csv', 'text/csv') }

      it "does not update the bulk_submission and adds errors" do
        expect {
          update
        }.not_to change {
          instance.bulk_submission.original_file.filename.to_s
        }

        expect(instance.errors[:uploaded_file]).to include("empty.csv is empty")
      end
    end

    context "with a file that is exactly one mebibyte" do
      before do
        allow(instance).to receive(:file_content).and_return(true)
      end

      let(:a_file) { fixture_file_upload('exactly_one_mebibyte.csv', 'text/csv') }

      it "replaces the original_file on the bulk submission" do
        expect {
          update
        }.to change {
          instance.bulk_submission.original_file.filename.to_s
        }.from('basic_bulk_submission.csv')
         .to('exactly_one_mebibyte.csv')
      end
    end

    context "with a file that is too big" do
      let(:a_file) { fixture_file_upload('one_byte_too_big.csv', 'text/csv') }

      it "does not update the bulk_submission and adds errors" do
        expect {
          update
        }.not_to change {
          instance.bulk_submission.original_file.filename.to_s
        }

        expect(instance.errors[:uploaded_file]).to include("one_byte_too_big.csv is more than 1MB")
      end
    end

    context "with a file whose CHECKED content_type is not acceptable" do
      let(:a_file) { fixture_file_upload('invalid_content_type_png_as_csv.csv') }

      it "does not update the bulk_submission and adds errors" do
        expect {
          update
        }.not_to change {
          instance.bulk_submission.original_file.filename.to_s
        }

        expect(instance.errors[:uploaded_file]).to include("invalid_content_type_png_as_csv.csv must be a CSV")
      end
    end

    context "with a file whose DECLARED content_type is not acceptable" do
      let(:a_file) { fixture_file_upload('basic_bulk_submission.csv', 'image/png') }

      it "does not update the bulk_submission and adds errors" do
        expect {
          update
        }.not_to change {
          instance.bulk_submission.original_file.filename.to_s
        }

        expect(instance.errors[:uploaded_file]).to include("basic_bulk_submission.csv must be a CSV")
      end
    end
  end
end
