
module DayMinute
  # number of minutes since the start of the day
  def day_minute
    hour * 60 + min
  end

  # number of seconds since the start of the day
  def day_second
    day_minute * 60 + sec
  end
end

ActiveSupport::TimeWithZone.send(:include, DayMinute)
DateTime.send(:include, DayMinute)
Time.send(:include, DayMinute)

