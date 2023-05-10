# centralize coverage config
# https://github.com/simplecov-ruby/simplecov#using-simplecov-for-centralized-config
#
unless ENV["NOCOVERAGE"]
  SimpleCov.start "rails" do
    add_filter 'lib/tasks'

    minimum_coverage 100
    enable_coverage :branch
    refuse_coverage_drop :line, :branch

    SimpleCov.at_exit do
      SimpleCov.result.format!
    end
  end
end
