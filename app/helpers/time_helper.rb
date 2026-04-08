module TimeHelper
  def gds_human_time(time)
    if time.min.zero?
      time.strftime("%-l%P")
    else
      time.strftime("%-l:%M%P")
    end
  end
end
