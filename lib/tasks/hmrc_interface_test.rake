require_relative "smoke_test"

namespace :hmrc_interface do
  desc "Run HMRC Interface test"
  task smoke_test: :environment do
    filter = {
      start_date: "2020-10-01",
      end_date: "2020-12-31",
      first_name: "Langley",
      last_name: "Yorke",
      dob: "1992-07-22",
      nino: "MN212451D"
    }

    smoke_test = HmrcInterface::SmokeTest.new(HmrcInterface.client, filter)
    smoke_test.call
  end
end
