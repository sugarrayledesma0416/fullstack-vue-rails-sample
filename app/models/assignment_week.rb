class AssignmentWeek
  include Enumerable
  
  def initialize(jd_week)
    @days = Array.new()
    @start_day = AssignmentWeek.start_date_of_jd_week(jd_week)
    @start_day.upto(@start_day+6) do |week_day|
      @days << AssignmentDay.new(:due_date => week_day)
    end
  end

  def <<(assignment)
    @days[assignment.due_date.wday] << assignment
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