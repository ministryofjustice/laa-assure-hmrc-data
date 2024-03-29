require "rails_helper"

RSpec.describe BulkSubmissionService do
  subject(:instance) { described_class.new(bulk_submission) }

  let(:bulk_submission) do
    create(:bulk_submission,
           :with_original_file,
           original_file_fixture_name: "multiple_bulk_submission.csv",
           original_file_fixture_content_type: "text/csv",)
  end

  describe "#bulk_submission" do
   it { expect(instance.bulk_submission).to eql(bulk_submission) }
  end

  describe "#parser" do
    context "when parser class passed as argument" do
      subject { described_class.new(bulk_submission, my_parser).parser }

      let(:my_parser) { Class.new }

      it { is_expected.to eql(my_parser) }
    end

    context "when no parser class passed as argument" do
      subject { described_class.new(bulk_submission).parser }

      it { is_expected.to eql(BulkSubmissionCsvParser) }
    end
  end

  describe "#call" do
    subject(:call) { instance.call }

    context "when bulk submission has valid original_file attached" do
      it "updates bulk_submission status to \"preparing\" initially" do
        allow(instance).to receive(:create_submission!).and_raise ZeroDivisionError, "oops, something went wrong"
        call
      rescue ZeroDivisionError
        expect(bulk_submission.reload.status).to eql("preparing")
      end

      it "creates submissions with expected attributes" do
        expect { call }.to change(Submission, :count).by(4)

        submissions = Submission.all.map {|e| e.attributes.with_indifferent_access }

        expect(submissions).to contain_exactly(hash_including(
            use_case: "one",
            period_start_at: Date.parse("2023-01-01"),
            period_end_at: Date.parse("2023-03-31"),
            first_name: "Jim",
            last_name: "Bob",
            dob: Date.parse("2001-01-01"),
            nino: "JA123456D",
          ), hash_including(
            use_case: "two",
            period_start_at: Date.parse("2023-01-01"),
            period_end_at: Date.parse("2023-03-31"),
            first_name: "Jim",
            last_name: "Bob",
            dob: Date.parse("2001-01-01"),
            nino: "JA123456D",
          ), hash_including(
            use_case: "one",
            period_start_at: Date.parse("2022-01-01"),
            period_end_at: Date.parse("2022-03-31"),
            first_name: "John",
            last_name: "Boy",
            dob: Date.parse("2002-01-01"),
            nino: "JA654321D",
          ), hash_including(
            use_case: "two",
            period_start_at: Date.parse("2022-01-01"),
            period_end_at: Date.parse("2022-03-31"),
            first_name: "John",
            last_name: "Boy",
            dob: Date.parse("2002-01-01"),
            nino: "JA654321D",
          ))
      end

      it "updates bulk_submission status to \"prepared\"" do
        expect{ call }
          .to change { bulk_submission.reload.status }
            .from("pending")
            .to("prepared")
      end

      it "enqueues HmrcInterfaceBulkSubmissionWorker job for bulk_submission", type: :worker do
        expect { call }
          .to change(HmrcInterfaceBulkSubmissionWorker, :jobs)
          .from([])
          .to(
            [
              hash_including(
                "retry" => true,
                "queue" => "default",
                "args" => [bulk_submission.id],
                "class" => "HmrcInterfaceBulkSubmissionWorker"
              )
            ]
          )
      end

      it "enqueues BulkSubmissionStatusWorker job for bulk_submission with delay", type: :worker do
        allow(BulkSubmissionStatusWorker).to receive(:perform_in).and_call_original

        expect { call }
          .to change(BulkSubmissionStatusWorker, :jobs)
          .from([])
          .to(
            [
              hash_including(
                "retry" => 6,
                "queue" => "default",
                "args" => [bulk_submission.id],
                "class" => "BulkSubmissionStatusWorker"
              )
            ]
          )

          # NOTE: delay calculated as "x * y * z" (2 * 2 * 7)
          # x = 2 (csv records);
          # y = 2 (use case requests each);
          # z = 7 (guestimate of time HMRC Int/HMRC takes to respond per request))
          expect(BulkSubmissionStatusWorker).to have_received(:perform_in).with(28.seconds, bulk_submission.id)
      end
    end

    context "when bulk submission original_file has whitespace in csv content" do
      let(:bulk_submission) do
        create(:bulk_submission,
               :with_content_for_original_file,
               content_for_original_file: content)
      end

      let(:content) do
        <<~CSV
          period_start_date    , period_end_date,first_name \t, last_name  \t, \tdate_of_birth    , nino
          2023-01-01      , 2023-03-31,  Jim   ,  Bob ,   2001-01-01 ,  JA123456D
        CSV
      end

      it "creates submissions with expected attributes" do
        expect { call }.to change(Submission, :count).by(2)

        submissions = Submission.all.map {|e| e.attributes.with_indifferent_access }

        expect(submissions).to contain_exactly(hash_including(
            use_case: "one",
            period_start_at: Date.parse("2023-01-01"),
            period_end_at: Date.parse("2023-03-31"),
            first_name: "Jim",
            last_name: "Bob",
            dob: Date.parse("2001-01-01"),
            nino: "JA123456D",
          ), hash_including(
            use_case: "two",
            period_start_at: Date.parse("2023-01-01"),
            period_end_at: Date.parse("2023-03-31"),
            first_name: "Jim",
            last_name: "Bob",
            dob: Date.parse("2001-01-01"),
            nino: "JA123456D",
          ))
      end
    end

    context "when bulk submission has no original_file attached" do
      let(:bulk_submission) { create(:bulk_submission) }

       it { expect { call }.to raise_error ArgumentError, /Cannot parse nil/ }
    end

    context "when bulk submission original_file has record with invalid date format" do
      let(:bulk_submission) do
        create(:bulk_submission,
               :with_content_for_original_file,
               content_for_original_file: content)
      end

      before do
        allow(Rails.logger).to receive(:error)
      end

      context "with invalid start_date" do
        let(:content) do
          <<~CSV
            period_start_date, period_end_date, first_name, last_name, date_of_birth, nino
            AA, 2023-03-31, Jim, Bob, 2001-01-01, JA123456D
          CSV
        end

        it "logs but does not raise error" do
          expect { call }.not_to raise_error

          expect(Rails.logger)
            .to have_received(:error)
            .with("invalid date for period_start_at")
            .twice

          expect(Submission.count).to be_zero
        end
      end

      context "with invalid end_date" do
        let(:content) do
          <<~CSV
            period_start_date, period_end_date, first_name, last_name, date_of_birth, nino
            2023-01-01, AA, Jim, Bob, 2001-01-01, JA123456D
          CSV
        end

        it "logs error, does not raise, does not create submission for use_case one and two" do
          expect { call }.not_to raise_error

          expect(Rails.logger)
            .to have_received(:error)
            .with("invalid date for period_end_at")
            .twice

          expect(Submission.count).to be_zero
        end
      end

      context "with invalid date_of_birth" do
        let(:content) do
          <<~CSV
            period_start_date, period_end_date, first_name, last_name, date_of_birth, nino
            2023-01-01, 2023-03-01, Jim, Bob, AA, JA123456D
          CSV
        end

        it "logs but does not raise error" do
          expect { call }.not_to raise_error

          expect(Rails.logger)
            .to have_received(:error)
            .with("invalid date for dob")
            .twice

          expect(Submission.count).to be_zero
        end
      end
    end

    context "when bulk submission original_file has invalid nino format" do
      let(:bulk_submission) do
        create(:bulk_submission,
               :with_content_for_original_file,
               content_for_original_file: content)
      end

      let(:content) do
        <<~CSV
          period_start_date, period_end_date, first_name, last_name, date_of_birth, nino
          2023-01-01, 2023-03-01, Jim, Bob, 2001-01-01, JAX12345D
        CSV
      end

      before do
        allow(Rails.logger).to receive(:error)
      end

      it "logs but does not raise error" do
        expect { call }.not_to raise_error

        expect(Rails.logger)
          .to have_received(:error)
          .with(/"JAX12345D" is not a valid national insurance number/)
          .twice

        expect(Submission.count).to be_zero
      end
    end
  end

  describe ".call" do
    subject(:call) { described_class.call(bulk_submission) }

    let(:instance) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:call)
    end

    it "sends call method to instance" do
      call
      expect(described_class).to have_received(:new).with(bulk_submission)
      expect(instance).to have_received(:call)
    end
  end
end
