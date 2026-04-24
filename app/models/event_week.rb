class EventWeek
  include Enumerable
  
  def initialize(jd_week, calendar_settings, active_month,assignments_map={})
    @days = Array.new()
    @start_day = EventWeek.start_date_of_jd_week(jd_week)
    @start_day.upto(@start_day+6) do |week_day|
      @days << EventDay.new(:date => week_day, :calendar_settings => calendar_settings, :active_month => active_month, :week => self)
    end
  end

  def <<(event)
    if event.is_a?(Assignment)
      @days[event.due_date.wday] << event
    else
      @days[event.date.wday] << event
    end
  end
  
  def each
    @days.each {|day| yield(day)}
  end
  
  private
  
  def self.jd_week(day)
    (day.jd+1)/7 # jd 0 is a monday so we add 1 to make sunday 0
  end
  
  def self.start_date_of_jd_week(week)
    Date.jd(week*7-1)
  end
end
