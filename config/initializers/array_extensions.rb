Dir[File.expand_path("../../lib/extensions/*.rb", __dir__)].each { |file| require file }

class Array
  include Extensions::ArrayExtension
end
