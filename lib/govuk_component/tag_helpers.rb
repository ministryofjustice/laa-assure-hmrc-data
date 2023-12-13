module GovukComponent
  module TagHelpers
    def govuk_status_tag(status = nil)
      govuk_tag(text: status.titlecase, colour: status_colour[status])
    end

  private
    def status_colour
      @status_colour ||= Hash.new('blue').tap do |hsh|
        hsh['pending'] = 'yellow'
        hsh['ready'] = 'green'
        hsh['exhausted'] = 'red'
      end
    end
  end
end
