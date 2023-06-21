FactoryBot.define do
  factory :bulk_submission do
    association :user
    status { 'pending' }

    trait :pending do
      status { 'pending' }
    end

    trait :processing do
      status { 'processing' }
    end

    trait :ready do
      status { 'ready' }
    end

    trait :discarded do
      discarded_at { Time.current - 1.second }
    end

    trait :undiscarded do
      discarded_at { nil }
    end

    trait :exhausted do
      status { 'exhausted' }
    end

    # name must be of a file that exists in `spec/fixtures/files/`
    transient do
      original_file_fixture_name { nil }
      original_file_fixture_content_type { nil }
    end

    trait :with_original_file do
      after(:build) do |bulk_submission, evaluator|
        file =  if evaluator.original_file_fixture_name
                  factorybot_file_fixture(evaluator.original_file_fixture_name,
                                          evaluator.original_file_fixture_content_type)
                else
                  factorybot_file_fixture("basic_bulk_submission.csv", "text/csv")
                end

        bulk_submission.original_file.attach(
          io: File.open(file),
          filename: file.original_filename,
          content_type: file.content_type
        )
      end
    end

    # name must be of a file that exists in `spec/fixtures/files/`
    transient do
      result_file_fixture_name { nil }
      result_file_fixture_content_type { nil }
    end

    trait :with_result_file do
      after(:build) do |bulk_submission, evaluator|
        file =  if evaluator.result_file_fixture_name
                  factorybot_file_fixture(evaluator.result_file_fixture_name,
                                          evaluator.result_file_fixture_content_type)
                else
                  factorybot_file_fixture("basic_bulk_submission-result.csv", "text/csv")
                end

        bulk_submission.result_file.attach(
          io: File.open(file),
          filename: file.original_filename,
          content_type: file.content_type
        )
      end
    end

    transient do
      content_for_original_file { nil }
    end

    trait :with_content_for_original_file do
      after(:build) do |bulk_submission, evaluator|
        content = evaluator.content_for_original_file ||
                    <<~CSV
                      nino, start_date, end_date, first_name, last_name, date_of_birth
                      JA123456D, 2023-01-01, 2023-03-01, Jim, Bob, 2001-01-01
                    CSV

        bulk_submission.original_file.attach(
          io: StringIO.new(content),
          filename: "content_supplied.csv",
          content_type: "text/csv"
        )
      end
    end
  end
end
