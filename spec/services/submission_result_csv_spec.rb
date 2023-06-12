require "rails_helper"

RSpec.describe SubmissionResultCsv do
  subject(:instance) { described_class.new(submission) }

  let(:bulk_submission) { create(:bulk_submission) }

  describe ".headers" do
    subject(:headers) { described_class.headers }

    let(:expected_headers) do
      %i[period_start_date
         period_end_date
         first_name
         last_name
         date_of_birth
         nino
         status
         comment
         tax_credit_annual_award_amount
         uc_one_data
         uc_two_data]
    end

    it "defaults to expected headers" do
      expect(headers).to match(expected_headers)
    end
  end

  describe "#row" do
    subject(:row) { instance.row }

    context "with a completed submission" do
      before do
        create(:submission,
               :for_john_doe,
               :with_completed_use_case_two_hmrc_interface_result,
               bulk_submission:)
      end

      let(:submission) do
        create(:submission,
               :for_john_doe,
               :with_completed_use_case_one_hmrc_interface_result,
               bulk_submission:)
      end

      let(:expected_values) do
        [
          "2020-10-01",
          "2020-12-31",
          "John", "Doe",
          "2001-07-21",
          "JA123456D",
          "completed",
          nil,
          nil,
          %([\n  {\n    "use_case": "use_case_one"\n  }\n]),
          %([\n  {\n    "use_case": "use_case_two"\n  }\n]),
        ]
      end

      it "matches expected values" do
        expect(row).to match(expected_values)
      end
    end

    context "with a completed submission with multiple child tax credit awards" do
      let(:submission) do
        create(:submission,
               :for_john_doe,
               :with_use_case_one_child_tax_credit,
               bulk_submission:)
      end

      it "includes most recent child tax credit award's total entitlement value" do
        expect(row).to include(8075.96)
      end
    end

    context "with a completed submission with multiple working tax credit awards" do
      let(:submission) do
        create(:submission,
               :for_john_doe,
               :with_use_case_one_working_tax_credit,
               bulk_submission:)
      end

      it "includes most recent working tax credit awards total entitlement value" do
        expect(row).to include(8075.96)
      end
    end

    context "with a completed submission with both child and working tax credit awards" do
      let(:submission) do
        create(:submission,
               :for_john_doe,
               :with_use_case_one_child_and_working_tax_credit,
               bulk_submission:)
      end

      it "includes most recent child tax credit awards total entitlement value" do
        expect(row).to include(9075.96)
      end
    end

    context "with a failed submission" do
      before do
        create(:submission,
               :for_john_doe,
               :with_failed_use_case_two_hmrc_interface_result,
               bulk_submission:)
      end

      let(:submission) do
        create(:submission,
               :for_john_doe,
               :with_failed_use_case_one_hmrc_interface_result,
               bulk_submission:)
      end

      # rubocop:disable Layout/LineLength
      let(:expected_values) do
        [
          "2020-10-01",
          "2020-12-31",
          "John", "Doe",
          "2001-07-21",
          "JA123456D",
          "failed",
          "submitted client details could not be found in HMRC service",
          nil,
          %([\n  {\n    "use_case": "use_case_one",\n    "correlation_id": "an-hmrc-interface-submission-uuid"\n  },\n  {\n    "error": "submitted client details could not be found in HMRC service"\n  }\n]),
          %([\n  {\n    "use_case": "use_case_two",\n    "correlation_id": "an-hmrc-interface-submission-uuid"\n  },\n  {\n    "error": "submitted client details could not be found in HMRC service"\n  }\n]),
        ]
      end
      # rubocop:enable Layout/LineLength

      it "matches expected values" do
        expect(row).to match(expected_values)
      end
    end

    context "with an exhausted submission" do
      before do
        create(:submission,
               :for_john_doe,
               :with_exhausted_use_case_two_hmrc_interface_result,
               bulk_submission:)
      end

      let(:submission) do
        create(:submission,
               :for_john_doe,
               :with_exhausted_use_case_one_hmrc_interface_result,
               bulk_submission:)
      end

      # rubocop:disable Layout/LineLength
      let(:expected_values) do
        [
          "2020-10-01",
          "2020-12-31",
          "John", "Doe",
          "2001-07-21",
          "JA123456D",
          "exhausted",
          "attempts to retrieve details for the individual were unsuccessful",
          nil,
          %({\n  "submission": "uc-one-hmrc-interface-submission-uuid",\n  "status": "processing",\n  "_links": [\n    {\n      "href": "http://www.example.com/api/v1/submission/result/uc-one-hmrc-interface-submission-uuid"\n    }\n  ]\n}),
          # TODO: handle failing test in which the keys are not coming back in order inserted
          %({\n  "_links": [\n    {\n      "href": "http://www.example.com/api/v1/submission/result/uc-two-hmrc-interface-submission-uuid"\n    }\n  ],\n  "status": "processing",\n  "submission": "uc-two-hmrc-interface-submission-uuid"\n}),
        ]
      end
      # rubocop:enable Layout/LineLength

      it "matches expected values" do
        expect(row).to match(expected_values)
      end
    end
  end
end
