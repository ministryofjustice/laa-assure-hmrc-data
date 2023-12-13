require 'rails_helper'

RSpec.describe GovukComponent::TagHelpers, type: :helper do
  include RSpecHtmlMatchers

  describe '#govuk_status_tag' do
    subject(:markup) { helper.govuk_status_tag('pending') }

    it 'adds tag with govuk class' do
      expect(markup).to have_tag(:strong, with: { class: 'govuk-tag' })
    end

    it 'yields status text to strong tag' do
      expect(markup).to have_tag(:strong, text: 'Pending')
    end

    context 'with known status' do
      subject(:markup) do
        helper.govuk_status_tag("ready")
      end

      it 'adds tag with color class, prepended by govuk class' do
        expect(markup).to have_tag(:strong, with: { class: 'govuk-tag govuk-tag--green' })
      end
    end

    context 'with status without colour mapping' do
      subject(:markup) do
        helper.govuk_status_tag('unknown')
      end

      it 'adds tag with blue color class, prepended by govuk class' do
        expect(markup).to have_tag(:strong, with: { class: 'govuk-tag govuk-tag--blue' })
      end
    end
  end
end
