# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :landing

  def landing
  end

  def home
  end
end
