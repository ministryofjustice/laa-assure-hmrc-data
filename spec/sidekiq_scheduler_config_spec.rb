require "rails_helper"
require "fugit"

RSpec.describe "sidekiq-scheduler config" do
  let(:sidekiq_file) { Rails.root.join("config/sidekiq.yml") }
  let(:schedules) do
    YAML.load_file(sidekiq_file).dig(:scheduler, :schedule) || []
  end

  context "when loading schedules" do
    it "all have valid cron syntax", :aggregate_failures do
      schedules.each do |name, config|
        cron = config["cron"] || config["every"] || config["at"] || config["in"]
        expect { Fugit.do_parse(cron) }.not_to raise_error,
        "cron syntax for #{name}, \"#{cron}\", is invalid"
      end
    end

    it "all have valid job/worker class", :aggregate_failures do
      schedules.each do |name, config|
        klass = config.fetch("class", name)
        expect { klass.constantize }.not_to raise_error,
        "class for #{name}, \"#{klass}\", does not exist"
      end
    end
  end
end
