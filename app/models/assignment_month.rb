class AssignmentMonth
  
  attr_reader :year,:month
  
  def initialize(date)
    @year = date.year
    @month = date.month
    @assignment_weeks = []
    @first_week = AssignmentWeek.jd_week(first_day_of_month)
    last_week = AssignmentWeek.jd_week(last_day_of_month)
    @first_week.upto(last_week) do |week|
      @assignment_weeks << AssignmentWeek.new(week)
    end
  end
  
  def <<(assignment)
    week_offset = AssignmentWeek.jd_week(assignment.due_date) - @first_week
    raise "Week out of Range" unless week_offset >= 0 && week_offset < @assignment_weeks.length
    @assignment_weeks[week_offset] << assignment
  end
  
  def next
    next_year = @year
    next_month = @month+1
    if (next_month == 13)
      next_month = 1
      next_year += 1
    end
    AssignmentMonth.new(Date.new(next_year,next_month,1))
  end
  
  def contains?(date)
    date >= first_day_of_month && date <= last_day_of_month
  end
  
  def to_s
    "%d-%02d" % [@year,@month]
  end
  
  def each()
    each_week do |week|
      week.each {|assignment_day| yield(assignment_day) if contains?(assignment_day.due_date) }
    end
  end
  
  def each_week
    @assignment_weeks.each {|week| yield(week)}
  end
  
  private

  def first_day_of_month
    Date.new(@year,@month,1)
  end

  def last_day_of_month
    Date.new(@year,@month,-1)
  end
  
end