class ApplicationController < ActionController::Base
  default_form_builder(GOVUKDesignSystemFormBuilder::FormBuilder)
  before_action :authenticate_user!, :out_of_hours_redirect

private
  def out_of_hours_redirect
    render "pages/service_out_of_hours", status: :temporary_redirect if out_of_hours?
  end

  def out_of_hours?(now = london.now)
    start_time = london.parse(Rails.configuration.x.business_hours.start)
    end_time   = london.parse(Rails.configuration.x.business_hours.end)

    now < start_time || now >= end_time
  end

  def london
    Time.find_zone('London')
  end
end
