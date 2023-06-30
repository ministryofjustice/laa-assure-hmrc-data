module FactoryBot::FileHelper
  def factorybot_file_fixture(filename, content_type)
    file_path = Rails.root.join("spec", "fixtures", "files", filename)
    Rack::Test::UploadedFile.new(file_path, content_type)
  end
end
