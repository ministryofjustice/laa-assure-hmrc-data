# frozen_string_literal: true

require 'rails'
require_relative 'tag_helpers'

module GovukComponent
  class Railtie < Rails::Railtie
    initializer 'govuk_component.tag_helpers' do
      ActiveSupport.on_load(:action_view) { include GovukComponent::TagHelpers }
    end
  end
end
