FactoryBot.define do
  factory :submission do
    bulk_submission

    period_start_at { 4.months.ago }
    period_end_at { 1.month.ago }
    use_case { :one }
    first_name { "Jim" }
    last_name { "Bob"}
    dob { 21.years.ago }
    nino { "JA123456D" }
    status { :pending }

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

    trait :exhausted do
      status { :exhausted }
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

    trait :for_john_doe do
      period_start_at { "2020-10-01".to_date }
      period_end_at { "2020-12-31".to_date }
      first_name { "John" }
      last_name { "Doe"}
      dob { "2001-07-21".to_date }
      nino { "JA123456D" }
    end

    trait :with_completed_use_case_one_hmrc_interface_result do
      status { :completed }
      use_case { :one }
      hmrc_interface_result { { data: [ use_case: "use_case_one" ] }.as_json }
    end

    trait :with_use_case_one_child_and_working_tax_credit do
      status { :completed }
      use_case { :one }
      hmrc_interface_result do
        {
          "data" => [
           { "use_case" => "use_case_one" },
           { "benefits_and_credits/working_tax_credit/applications"=>
               [{ "awards"=>
                  [{ "payments"=>[],
                     "totalEntitlement"=>8075.96 },
                   { "payments"=>[],
                     "totalEntitlement"=>8008.07 }] }] },
           { "benefits_and_credits/child_tax_credit/applications"=>
               [{ "awards"=>
                  [{ "payments"=>[],
                     "totalEntitlement"=>9075.96 },
                   { "payments"=>[],
                     "totalEntitlement"=>9008.07 }] }] }
          ]
        }.as_json
      end
    end

    trait :with_use_case_one_gross_income_for_nics do
      status { :completed }
      use_case { :one }
      hmrc_interface_result do
        {
          "data" => [
           { "use_case" => "use_case_one" },
           { "income/paye/paye" => {
                "income" => [
                  {
                    "paymentDate" => "2022-03-17",
                    "grossEarningsForNics" => {
                      "inPayPeriod1" => 333.33
                    },
                  },
                  {
                    "paymentDate" => "2022-02-20",
                    "grossEarningsForNics" => {
                      "inPayPeriod1" => 666.66
                    },
                  },
                ]
              }
            }
          ]
        }.as_json
      end
    end

    # NOTE: reflects real data where some income entries have no `employeeNics`
    trait :with_use_case_one_employee_nics do
      status { :completed }
      use_case { :one }
      hmrc_interface_result do
        {
          "data" => [
           { "use_case" => "use_case_one" },
           { "income/paye/paye" => {
                "income" => [
                  {
                    "employeeNics" => {
                      "inPayPeriod1" => 222.22
                    },
                  },
                  { "employeeNics" => {
                      "inPayPeriod1" => 444.44
                    },
                  },
                  {
                  },
                ]
              }
            }
          ]
        }.as_json
      end
    end

    trait :with_use_case_one_employment_paye do
      status { :completed }
      use_case { :one }
      hmrc_interface_result do
         {
            "data" => [
              { "use_case" => "use_case_one" },
              {
                "employments/paye/employments" => [
                  {
                    "endDate" => "2099-12-31",
                    "startDate" => "2023-01-26"
                  },
                  {
                    "endDate" => "2022-11-11",
                    "startDate" => "2022-09-11"
                  }
                ]
              },
            ]
          }.as_json
      end
    end

    trait :with_use_case_one_self_assessment_summary do
      status { :completed }
      use_case { :one }
      hmrc_interface_result do
        {
          "data" => [
            { "use_case" => "use_case_one" },
            {
              "income/sa/summary/selfAssessment" => {
                "taxReturns" => [
                  {
                    "taxYear" => "2019-20",
                    "summary" => [
                      {
                        "totalIncome" => 6487
                      }
                    ]
                  },
                  {
                    "taxYear" => "2020-21",
                    "summary" => [
                      {
                        "totalIncome" => 7995
                      }
                    ]
                  },
                  {
                    "taxYear" => "2021-22",
                    "summary" => [
                      {
                        "totalIncome" => 6824
                      }
                    ]
                  }
                ]
              }
            },
          ]
        }.as_json
      end
    end

    trait :with_completed_use_case_two_hmrc_interface_result do
      status { :completed }
      use_case { :two }
      hmrc_interface_result { { data: [ use_case: "use_case_two" ] }.as_json }
    end

    trait :with_failed_use_case_one_hmrc_interface_result do
      status { :failed }
      use_case { :one }
      hmrc_interface_result do
        {
          data:
            [
              { use_case: "use_case_one",
                correlation_id: "an-hmrc-interface-submission-uuid" },
              { error: "submitted client details could not be found in HMRC service" },
            ]
        }.as_json
      end
    end

    trait :with_failed_use_case_two_hmrc_interface_result do
      status { :failed }
      use_case { :two }
      hmrc_interface_result do
        {
          data:
            [
              { use_case: "use_case_two",
                correlation_id: "an-hmrc-interface-submission-uuid" },
              { error: "submitted client details could not be found in HMRC service" },
            ]
        }.as_json
      end
    end

    trait :with_exhausted_use_case_one_hmrc_interface_result do
      status { :exhausted }
      use_case { :one }
      hmrc_interface_result do
        {
          submission: "uc-one-hmrc-interface-submission-uuid",
          status: "processing",
          _links: [href: "http://www.example.com/api/v1/submission/result/uc-one-hmrc-interface-submission-uuid"],
        }.as_json
      end
    end

    trait :with_exhausted_use_case_two_hmrc_interface_result do
      status { :exhausted }
      use_case { :two }
      hmrc_interface_result do
        {
          submission: "uc-two-hmrc-interface-submission-uuid",
          status: "processing",
          _links: [href: "http://www.example.com/api/v1/submission/result/uc-two-hmrc-interface-submission-uuid"],
        }.as_json
      end
    end
  end
end
