SubmissionRecord = Struct.new('SubmissionRecord',
                              :period_start_date,
                              :period_end_date,
                              :first_name,
                              :last_name,
                              :date_of_birth,
                              :nino) do
  def period_start_at
    @period_start_at ||= Date.parse(period_start_date)
  rescue Date::Error => e
    raise Date::Error, "#{e.message} for #{__method__}"
  end

  def period_end_at
    @period_end_at ||= Date.parse(period_end_date)
  rescue Date::Error => e
    raise Date::Error, "#{e.message} for #{__method__}"
  end

  def dob
    @dob ||= Date.parse(date_of_birth)
  rescue Date::Error => e
    raise Date::Error, "#{e.message} for #{__method__}"
  end
end
