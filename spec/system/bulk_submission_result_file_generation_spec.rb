require "rails_helper"

RSpec.describe "Generation of a result file", type: :worker do
  before do
    bulk_submission
  end

  let(:bulk_submission) do
    BulkSubmission.create!(
      user_id: create(:user).id,
      original_file: fixture_file_upload('basic_bulk_submission.csv'),
      status: :pending,
    )
  end

  let(:perform_inline) do
    Sidekiq::Testing.inline! do
      BulkSubmissionsWorker.perform_async
    end
  end

  let(:row_as_hash) { csv[0].to_h.except("uc_one_data", "uc_two_data").symbolize_keys }
  let(:csv) { CSV.parse(bulk_submission.result_file.download, headers: :first_row) }

  let(:expected_headers) do
    %w[period_start_date
       period_end_date
       first_name
       last_name
       date_of_birth
       nino
       status
       comment
       tax_credit_annual_award_amount
       clients_income_from_employment
       clients_ni_contributions_from_employment
       start_and_end_dates_for_employments
       most_recent_payment_from_employment
       clients_income_from_self_employment
       clients_income_from_other_sources
       most_recent_payment_from_other_sources
       uc_one_data
       uc_two_data]
  end

  context "with any completed hmrc result" do
    include_context "with stubbed hmrc-interface result completed"

    let(:expected_row_as_hash) do
      {
        period_start_date: "2023-01-01",
        period_end_date: "2023-04-01",
        first_name: "Jim",
        last_name: "Bob",
        date_of_birth: "2001-01-01",
        nino: "JA123456D",
        status: "completed",
        comment: "",
      }
    end

    it "result file contains expected headers" do
      perform_inline
      expect(csv.headers)
        .to match(expected_headers),
           "expected #{expected_headers-csv.headers}\ngot: #{csv.headers-expected_headers}"
    end

    it "result file contains details from original_file" do
      perform_inline
      expect(row_as_hash)
        .to match(hash_including(expected_row_as_hash)),
          "expected: #{expected_row_as_hash.to_a-row_as_hash.to_a}\ngot: #{row_as_hash.to_a-expected_row_as_hash.to_a}"
    end
  end

  context "with income paye and employments hmrc result" do
    include_context "with stubbed hmrc-interface result with income paye and employments completed"

    let(:expected_row_as_hash) do
      {
        tax_credit_annual_award_amount: "",
        clients_income_from_employment: "3867.26",
        clients_ni_contributions_from_employment: "165.20999999999998",
        start_and_end_dates_for_employments: "2023-01-26 to 2099-12-31\n2022-09-11 to 2022-11-11",
        most_recent_payment_from_employment: "2022-04-05: 1431.07",
        clients_income_from_self_employment: "",
        clients_income_from_other_sources: "0.0",
        most_recent_payment_from_other_sources: "2022-04-05: 0.0"
      }
    end

    it "results file contains expected mapped values" do
      perform_inline
      expect(row_as_hash)
        .to match(hash_including(expected_row_as_hash)),
          "expected: #{expected_row_as_hash.to_a-row_as_hash.to_a}\ngot: #{row_as_hash.to_a-expected_row_as_hash.to_a}"
    end
  end

  context "with summary self assessment tax returns hmrc result" do
    include_context "with stubbed hmrc-interface result with self assessment tax returns completed"

    let(:expected_row_as_hash) do
      {
        tax_credit_annual_award_amount: "",
        clients_income_from_employment: "0",
        clients_ni_contributions_from_employment: "0",
        start_and_end_dates_for_employments: "",
        most_recent_payment_from_employment: "",
        clients_income_from_self_employment: "2019-20: 6487\n2020-21: 7995\n2021-22: 6824",
        clients_income_from_other_sources: "0",
        most_recent_payment_from_other_sources: ""
      }
    end

    it "results file contains expected mapped values" do
      perform_inline
      expect(row_as_hash)
        .to match(hash_including(expected_row_as_hash)),
          "expected: #{expected_row_as_hash.to_a-row_as_hash.to_a}\ngot: #{row_as_hash.to_a-expected_row_as_hash.to_a}"
    end
  end

  context "with benefits and credits hrmc result" do
    include_context "with stubbed hmrc-interface result with benefits and credits completed"

    let(:expected_row_as_hash) do
      {
        tax_credit_annual_award_amount: "8075.96",
        clients_income_from_employment: "0",
        clients_ni_contributions_from_employment: "0",
        start_and_end_dates_for_employments: "",
        most_recent_payment_from_employment: "",
        clients_income_from_self_employment: "",
        clients_income_from_other_sources: "0",
        most_recent_payment_from_other_sources: ""
      }
    end

    it "results file contains expected mapped values" do
      perform_inline
      expect(row_as_hash)
        .to match(hash_including(expected_row_as_hash)),
          "expected: #{expected_row_as_hash.to_a-row_as_hash.to_a}\ngot: #{row_as_hash.to_a-expected_row_as_hash.to_a}"
    end
  end
end
