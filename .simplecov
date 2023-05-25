# centralize coverage config
# https://github.com/simplecov-ruby/simplecov#using-simplecov-for-centralized-config
#
unless ENV["NOCOVERAGE"]
  SimpleCov.start "rails" do
    add_filter 'lib/tasks'
    add_group "Forms", "app/forms"
    add_group "Services", "app/services"
    add_group "Validators", "app/validators"
    add_group "Workers", "app/workers"

    minimum_coverage 99
    enable_coverage :branch
    refuse_coverage_drop :line, :branch

    SimpleCov.at_exit do
      SimpleCov.result.format!
    end
  end
end
