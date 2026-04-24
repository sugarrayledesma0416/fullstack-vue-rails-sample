class EventMonth
  
  attr_reader :year, :month
  
  def initialize(date, calendar_settings, assignments_map={})
    @year = date.year
    @month = date.month
    @calendar_settings = calendar_settings
    @from = @calendar_settings.start_date
    @to = @calendar_settings.end_date
    @event_weeks = []
    @first_week = EventWeek.jd_week(first_day_of_month)
    last_week = EventWeek.jd_week(last_day_of_month)
    @first_week.upto(last_week) do |week|
      @event_weeks << EventWeek.new(week, @calendar_settings, @month,assignments_map)
    end
  end
  
  def <<(event)
    if event.is_a?(Assignment)
      week_offset = EventWeek.jd_week(event.due_date) - @first_week
    else
      week_offset = EventWeek.jd_week(event.date) - @first_week
    end
    raise "Week out of Range" unless week_offset >= 0 && week_offset < @event_weeks.length
    @event_weeks[week_offset] << event
  end

  def next
    next_year = @year
    next_month = @month+1
    if (next_month == 13)
      next_month = 1
      next_year += 1
    end
    EventMonth.new(Date.new(next_year, next_month, 1), @calendar_settings)
  end

  def days
    days = []
    each_week do |week|
      week.each {|event_day| days << event_day if contains?(event_day.date) }
    end
    days
  end
  
  def contains?(date)
    date >= first_day_of_month && date <= last_day_of_month
  end
  
  def to_s
    "%d-%02d" % [@year,@month]
  end
  
  def each()
    each_week do |week|
      week.each {|event_day| yield(event_day) if contains?(event_day.date) }
    end
  end
  
  def each_week
    @event_weeks.each {|week| yield(week)}
  end
  
  private

  def first_day_of_month
    Date.new(@year, @month,1)
  end

  def last_day_of_month
    Date.new(@year, @month,-1)
  end
  
end
