FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "test.user.#{n}@example.co.uk" }

    trait :with_matching_stubbed_oauth_details do
      email { "jim.bob@example.co.uk" }
      first_name { "Jim" }
      last_name { "Bob" }
      auth_provider { "azure_ad" }
      auth_subject_uid { "jim-bob-fake-uid" }
    end
  end
end
