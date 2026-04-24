Time::DATE_FORMATS.merge!(
  abr_weekday_month_ordinal_with_time: lambda do |time| # Mon, Feb 8th 5:15 AM
    time.strftime("%a, %b #{time.day.ordinalize} %l:%M %p")
  end,
  activity_due_time: lambda do |time|                  # 2:46 p.m.
    time.strftime('%l:%M %p').downcase.gsub(/([a-z])/) { |m| "#{m}." }
  end,
  compact_date_and_time: '%m/%d/%Y %l:%M %p',          # 09/25/2011  5:15 AM
  date_time_selector_format: '%m/%d/%Y %I:%M %p',      # 09/25/2011 05:15 AM
  friendly: '%a, %b %d %Y %I:%M %p %Z',                # Thu, Sep 10 2009 05:30 AM EDT
  gradebook_cell: '%b %d %I:%M %p',                    # Sep 10 05:30 AM
  gradebook_cell_short: '%b %d',                       # Sep 10
  month_ordinal: lambda do |time|                      # February 8th
    time.strftime("%B #{time.day.ordinalize}")
  end,
  month_ordinal_with_time: lambda do |time|            # February 8th 5:15 AM
    time.strftime("%B #{time.day.ordinalize} %l:%M %p")
  end,
  num_month_date_no_leading_zero: '%-m/%-d',           # 10/1
  ordinal_with_zone: lambda do |time|                  # Mon, Feb 8th 5:15 AM EDT
    time.strftime("%a, %b #{time.day.ordinalize} %l:%M %p %Z")
  end,
  day_month_ordinal_with_time: lambda do |time|        # Mon, Feb 8th 5:15 AM
    time.strftime("%a, %b #{time.day.ordinalize} %l:%M %p")
  end,
  relative_weekday_month_ordinal: lambda do |time|     # Today, February 8th
    DateTimeHelper.format_relative_day(time)
  end,
  short: '%m/%d/%Y',                                   # 08/31/2009
  short_day_full_month: '%a, %B %d, %Y',               # Fri, September 30, 2011
  short_month: '%b %d, %Y',                            # Sep 10, 2009
  standard: '%b %d %Y %I:%M %p',                       # Sep 10 2009 05:30 AM
  time_with_zone: '%l:%M %p %Z',                       # 2:46 PM GMT
  time_without_zone: '%l:%M %p',                       # 2:46 PM
  tiny: '%m/%d/%y',                                    # 08/31/09
  toc_due_date: lambda do |time|                       # Today/Tomorrow/Mon 2/8
    DateTimeHelper.format_relative_day_or_date(time)
  end,
  toc_due_date_with_time: lambda do |time|             # Today/Tomorrow/Mon 2/8 5:15 AM
    # unbold today word here to do not change in other part
    # where format_relative_day_or_date is called.
    "#{DateTimeHelper.format_relative_day_or_date(time)} " \
      "#{time.strftime('%l:%M %p')}".gsub(/<b>|<\/b ?>/, '')
  end,
  relative_day_or_short_date: lambda do |time|         # Today/Tomorrow/Oct 08
    DateTimeHelper.relative_day(time) || time.strftime('%b %d')
  end,
  relative_day_or_month_unpadded: lambda do |time|      # Today/Tomorrow/October 8
    DateTimeHelper.relative_day(time) || time.strftime('%B %-d')
  end,
  today_or_date: lambda do |time|                      # Today/Mon 2/8
    DateTimeHelper.format_today_or_date(time)
  end,
  two_line: '%b %d %Y<br/>%I:%M %p',                   # Sep 10<br/>05:30 AM
  weekday_month_ordinal: lambda do |time|              # Monday, February 8th
    time.strftime("%A, %B #{time.day.ordinalize}")
  end,
  short_weekday_month_ordinal: lambda do |time|              # Mon, Feb 8th
    time.strftime("%a, %b #{time.day.ordinalize}")
  end,
  weekday_month_ordinal_with_time: lambda do |time|    # Monday, February 8th 5:15 AM
    time.strftime("%A, %B #{time.day.ordinalize} %l:%M %p")
  end
)
