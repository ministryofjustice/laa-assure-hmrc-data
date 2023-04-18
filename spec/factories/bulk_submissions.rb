FactoryBot.define do
  factory :bulk_submission do
    association :user
    status { 'pending' }

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
  end
end
