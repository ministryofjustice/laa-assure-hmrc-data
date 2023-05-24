class CsvResultRow
  attr_reader :submission

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
    [
      period_start_at.to_fs(:csv),
      period_end_at.to_fs(:csv),
      first_name,
      last_name,
      dob.to_fs(:csv),
      nino,
      status,
      comment,
      uc_one_data,
      uc_two_data,
    ]
  end

private

  def comment
    if exhausted?
      "attempts to retrieve details for the individual were unsuccessful"
    elsif failed?
      hmrc_interface_result["data"][1]["error"]
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
