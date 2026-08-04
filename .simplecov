# centralize coverage config
# https://github.com/simplecov-ruby/simplecov#using-simplecov-for-centralized-config
#
SimpleCov.skip 'lib/tasks'
SimpleCov.group "Forms", "app/forms"
SimpleCov.group "Services", "app/services"
SimpleCov.group "Validators", "app/validators"
SimpleCov.group "Workers", "app/workers"
SimpleCov.minimum_coverage 100
SimpleCov.enable_coverage :branch
SimpleCov.refuse_coverage_drop :line, :branch
