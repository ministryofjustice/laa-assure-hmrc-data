class QueueNameService
  def self.call
    new.call
  end

  def call
    if Rails.configuration.x.environment == "uat"
      "#{uat_queue_name}-submissions"
    else
      "submissions"
    end
  end

  def uat_queue_name
    branch_name = Rails.configuration.x.status.app_branch
    branch_name.tr(" _/[]().", "-")
  end
end
