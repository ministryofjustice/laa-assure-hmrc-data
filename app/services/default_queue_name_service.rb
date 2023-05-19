class DefaultQueueNameService
  def self.call
    new.call
  end

  def initialize
  end

  # creating a queue does not create the process set to process them
  def call
    if Rails.host.uat?
      "default-#{uat_queue_name}"
    else
      "default"
    end
  end

private

  def uat_queue_name
    branch_name = Rails.configuration.x.status.app_branch
    branch_name.tr(" _/[]().", "-")
  end
end
