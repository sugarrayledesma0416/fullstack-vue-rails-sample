module DateTimeHelper
  # format a date time string
  def format_date_time(datetime, format = :short, in_zone = Time.zone)
    if datetime
      apply_zone = lambda { |zone, fn, fn_args|
        Time.use_zone(zone) do
          fn.call(fn_args)
        end
      }

      if datetime.instance_of?(Date)
        datetime = apply_zone.call(in_zone,
                                   lambda { |datetime| datetime.to_datetime },
                                   datetime)
      elsif datetime.blank?
        datetime = apply_zone.call(in_zone,
                                   lambda { |datetime| Time.zone.now },
                                   datetime)
      elsif datetime.instance_of?(String)
        datetime = apply_zone.call(in_zone,
                                   lambda { |datetime| Time.zone.parse(datetime) },
                                   datetime)
      else
        datetime = apply_zone.call(in_zone,
                                   lambda { |datetime| Time.zone.at(datetime.to_i) },
                                   datetime)
      end
      datetime.to_formatted_s(format).html_safe
    end
  end

  def safe_date_string(date)
    date_string = date.to_s
    safe_date = Date.parse(date_string) rescue nil
    (safe_date&.strftime('%m/%d/%Y'.freeze)) || date_string
  end

  def format_date_to_mm_dd_yyyy(date)
    date.to_s if date && date.is_a?(Date)
  end

  module_function def format_relative_day_or_date(datetime)
    relative_day(datetime) || datetime.strftime('%a %m/%d'.freeze)
  end

  module_function def relative_day(datetime)
    date_now = Time.zone.now.to_date
    day_diff = datetime.to_date - date_now
    if day_diff == 1
      '<b>Tomorrow</b>'.freeze.html_safe
    elsif day_diff.zero?
      '<b>Today</b>'.freeze.html_safe
    end
  end

  module_function def format_relative_day(datetime)
    day_str = relative_day(datetime) || '\1'
    datetime.strftime("%A, %B #{datetime.day.ordinalize}").gsub!(/^(\w+day)/, day_str)
  end

  module_function def format_today_or_date(datetime)
    if Date.current == datetime.to_date
      'Today'.freeze
    else
      datetime.strftime('%a %-m/%-d'.freeze)
    end
  end
end
