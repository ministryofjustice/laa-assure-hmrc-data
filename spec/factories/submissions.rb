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
    status { :pending }

    # responses
    hmrc_interface_id { nil }
    hmrc_interface_result { "{}" }

    trait :pending do
      status { :pending }
    end

    trait :preparing do
      status { :preparing }
    end

    trait :prepared do
      status { :prepared }
    end

    trait :submitting do
      status { :submitting }
    end

    trait :submitted do
      status { :submitted }
    end

    trait :completing do
      status { :completing }
    end

    trait :processing do
      status { :processing }
    end

    trait :completed do
      status { :completed }
    end

    trait :failed do
      status { :failed }
    end

    trait :for_sandbox_applicant do
      period_start_at { "2020-10-01".to_date }
      period_end_at { "2020-12-31".to_date }
      use_case { :one }
      first_name { "Langley" }
      last_name { "Yorke"}
      dob { "1992-07-22".to_date }
      nino { "MN212451D" }
      status { :pending }
    end
  end
end
