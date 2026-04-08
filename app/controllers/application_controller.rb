class ApplicationController < ActionController::Base
  default_form_builder(GOVUKDesignSystemFormBuilder::FormBuilder)
  before_action :authenticate_user!, :out_of_hours_redirect

private
  def out_of_hours_redirect
    render "pages/service_out_of_hours", status: :temporary_redirect if out_of_hours?
  end

  def out_of_hours?
    Time.zone.now < Rails.configuration.x.business_hours.start.to_time ||
    Time.zone.now >= Rails.configuration.x.business_hours.end.to_time
  end
end
