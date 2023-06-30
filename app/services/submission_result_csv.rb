class SubmissionResultCsv
  include HmrcInterfaceResultable

  attr_reader :submission

  def self.headers(original_headers = SubmissionRecord.members)
    original_headers + %i[status
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

  delegate :period_start_at,
           :period_end_at,
           :first_name,
           :last_name,
           :dob,
           :nino,
           :status,
           :hmrc_interface_result,
           :exhausted?,
           :failed?,
           :bulk_submission_id,
           to: :submission

  def initialize(submission)
    @submission = submission
  end

  def row
    @row = [
      period_start_at.to_fs(:csv),
      period_end_at.to_fs(:csv),
      first_name,
      last_name,
      dob.to_fs(:csv),
      nino,
      status,
      comment,
      tax_credit_annual_award_amount,
      clients_income_from_employment,
      clients_ni_contributions_from_employment,
      start_and_end_dates_for_employments,
      most_recent_payment_from_employment,
      clients_income_from_self_employment,
      clients_income_from_other_sources,
      most_recent_payment_from_other_sources,
      uc_one_data,
      uc_two_data,
    ]

    raise StandardError, "mismatched header and row element size" if self.class.headers.size != @row.size
    @row
  end

private

  def comment
    if exhausted?
      "attempts to retrieve details for the individual were unsuccessful"
    elsif failed?
      error
    end
  end

  def uc_one_data
    if exhausted?
      JSON.pretty_generate(hmrc_interface_result)
    else
      JSON.pretty_generate(hmrc_interface_result["data"])
    end
  end

  def uc_two_data
    return unless matching_uc_two_submission

    if matching_uc_two_submission.exhausted?
      JSON.pretty_generate(matching_uc_two_submission.hmrc_interface_result)
    else
      JSON.pretty_generate(matching_uc_two_submission.hmrc_interface_result["data"])
    end
  end

  def matching_uc_two_submission
    @matching_uc_two_submission ||= submission.class
                                      .find_by(bulk_submission_id:,
                                               use_case: "two",
                                               nino:,
                                               dob:,
                                               first_name:,
                                               last_name:)
  end
end

