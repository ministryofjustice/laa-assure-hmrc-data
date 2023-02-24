# centralize coverage config
# https://github.com/simplecov-ruby/simplecov#using-simplecov-for-centralized-config
#
unless ENV["NOCOVERAGE"]
  SimpleCov.start "rails" do
    minimum_coverage 75
    enable_coverage :branch
    refuse_coverage_drop :line, :branch

    add_filter "config/"
    add_filter "spec/"

    SimpleCov.at_exit do
      SimpleCov.result.format!
    end
  end
end
