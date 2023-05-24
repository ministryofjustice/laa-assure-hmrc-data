require "rails_helper"

RSpec.describe CsvResultRow do
  subject(:instance) { described_class.new(submission) }

  let(:bulk_submission) { create(:bulk_submission) }

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
          %([\n  {\n    "use_case": "use_case_one"\n  }\n]),
          %([\n  {\n    "use_case": "use_case_two"\n  }\n]),
        ]
      end

      it "matches expected values" do
        expect(row).to match(expected_values)
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
