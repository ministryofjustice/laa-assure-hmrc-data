Dir[Rails.root.join('lib/extensions/*.rb')].each { |file| require file }

module Rails
  extend RailsModuleExtension
end
