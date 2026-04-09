# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:landing, :service_out_of_hours]

  def landing
  end

  def home
  end

  def service_out_of_hours
  end
end
