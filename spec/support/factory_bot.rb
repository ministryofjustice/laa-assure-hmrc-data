require "factory_bot"
require_relative "factory_bot_file_helper"

RSpec.configure { |config| config.include FactoryBot::Syntax::Methods }

FactoryBot::SyntaxRunner.class_eval { include FactoryBot::FileHelper }
