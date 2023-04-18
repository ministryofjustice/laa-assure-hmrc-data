require "factory_bot"
require_relative "factory_bot_file_helper"

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

FactoryBot::SyntaxRunner.class_eval { include FactoryBot::FileHelper }
