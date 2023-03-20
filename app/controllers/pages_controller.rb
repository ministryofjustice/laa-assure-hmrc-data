# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :authenticate_user!, only: :home

  def landing
  end

  def home
  end
end
