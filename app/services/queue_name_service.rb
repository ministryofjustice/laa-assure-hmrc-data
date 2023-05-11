class QueueNameService
  def self.call(use_case)
    new(use_case).call
  end

  def initialize(use_case)
    @use_case = use_case
  end

  def call
    if Rails.configuration.x.host_env == "uat"
      "uc-#{@use_case}-#{uat_queue_name}-submissions"
    else
      "uc-#{@use_case}-submissions"
    end
  end

private

  def uat_queue_name
    branch_name = Rails.configuration.x.status.app_branch
    branch_name.tr(" _/[]().", "-")
  end
end
