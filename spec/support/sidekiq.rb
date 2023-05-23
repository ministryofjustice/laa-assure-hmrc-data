# https://github.com/sidekiq/sidekiq/wiki/Testing

RSpec.configure do |config|
  config.before(:each, type: :worker) do
    # make sure jobs don't linger between tests
    Sidekiq::Worker.clear_all
  end
end
