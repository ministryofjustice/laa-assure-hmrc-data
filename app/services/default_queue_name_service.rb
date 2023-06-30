class DefaultQueueNameService
  def self.call
    new.call
  end

  def call
    Rails.host.uat? ? "default-#{uat_queue_name}" : "default"
  end

  private

  def uat_queue_name
    branch_name = Rails.configuration.x.status.app_branch
    branch_name.tr(" _/[]().", "-")
  end
end
