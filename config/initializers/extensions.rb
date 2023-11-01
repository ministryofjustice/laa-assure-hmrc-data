Dir[File.expand_path("../../lib/extensions/*.rb", __dir__)].each { |file| require file }

module Rails
  extend RailsModuleExtension
end

class Array
  include ArrayExtension
end
