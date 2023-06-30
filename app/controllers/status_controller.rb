class StatusController < ApplicationController
  skip_before_action :authenticate_user!, :verify_authenticity_token

  def status
    checks = {
      database: database_alive?,
      redis: redis_alive?,
      sidekiq: sidekiq_alive?,
      sidekiq_queue: sidekiq_queue_healthy?
    }

    status = :bad_gateway unless checks.except(:sidekiq_queue).values.all?
    render status:, json: { checks: }
  end

  def ping
    render json: {
             "build_date" => Rails.configuration.x.status.build_date,
             "build_tag" => Rails.configuration.x.status.build_tag,
             "git_commit" => Rails.configuration.x.status.git_commit,
             "app_branch" => Rails.configuration.x.status.app_branch
           }
  end

  private

  def database_alive?
    ActiveRecord::Base.connection.active?
  rescue PG::ConnectionBad
    false
  end

  def redis_alive?
    Sidekiq.redis(&:info)
    true
  rescue StandardError
    false
  end

  def sidekiq_alive?
    ps = Sidekiq::ProcessSet.new
    # rubocop:disable Style/ZeroLengthPredicate
    !ps.size.zero?
    # rubocop:enable Style/ZeroLengthPredicate
  rescue StandardError
    false
  end

  def sidekiq_queue_healthy?
    dead = Sidekiq::DeadSet.new
    retries = Sidekiq::RetrySet.new
    # rubocop:disable Style/ZeroLengthPredicate
    dead.size.zero? && retries.size.zero?
    # rubocop:enable Style/ZeroLengthPredicate
  rescue StandardError
    false
  end
end
