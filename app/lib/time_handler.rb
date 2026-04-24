module TimeHandler
  def set_time_from_params(hr, min, ampm)
    case ampm
      when 'PM'
          hr = hr.to_i + 12 unless (hr == '12')
      when 'AM'
          hr = '00' if (hr == '12')
    end
   Time.utc(1,1,1,hr,min,0)
  end
  private :set_time_from_params

  def in_time_zone(new_zone)
    sys_time = Time.zone
    Time.zone = new_zone
    val = yield
    Time.zone = sys_time
    return val
  end

  def date_time_from_parts(date, time, zone)
    in_time_zone(zone) { Time.zone.parse("#{date.strftime("%Y-%m-%d")} #{time.strftime("%H:%M:%S")}") }
  end

  def date_for_zone(tz = nil)
    tz ||= Time.zone
    time_for_zone(tz).to_date
  end

  def time_for_zone(tz = nil)
    tz ||= Time.zone
    date_time = nil
    in_time_zone(tz) { date_time = Time.zone.now }
    date_time
  end
end
