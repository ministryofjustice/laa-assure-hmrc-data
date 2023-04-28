FactoryBot.define do
  factory :submission do
    # association with uploaded file
    association :bulk_submission

    # attributes created from uploaded file rows
    period_start_at { 4.months.ago }
    period_end_at { 1.month.ago }
    use_case { :one }
    first_name { "Jim" }
    last_name { "Bob"}
    dob { 21.years.ago }
    nino { "JA123456D" }
    status { :processing }

    # responses
    hmrc_interface_id { nil }
    hmrc_interface_result { "{}" }

    trait :processing do
      status { :processing }
    end

    trait :completed do
      status { :completed }
    end

    trait :failed do
      status { :failed }
    end
  end
end
