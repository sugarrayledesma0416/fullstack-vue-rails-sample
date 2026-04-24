
class AssignmentCalendar
  def initialize(from, to)
    @assignment_months = Array.new
    @assignment_months << AssignmentMonth.new(from)
    until @assignment_months.last.contains?(to) do
      @assignment_months << @assignment_months.last.next
    end
    @first_month_index = month_index(from)
  end

  def <<(assignment)
    month_offset = month_index(assignment.due_date) - @first_month_index
    raise "Month out of Range" unless month_offset >= 0 && month_offset < @assignment_months.length
    @assignment_months[month_offset] << assignment
  end

  def each(&block)
    each_month {|month| month.each(&block)}
  end
  
  def each_week(&block)
    each_month {|month| month.each_week(&block)}
  end
  
  def each_month
    @assignment_months.each {|month| yield(month)}
  end
  
  def empty?
    @assignment_months.empty?
  end
  
  private
  
  def month_index(date)
    date.year*12+date.month-1
  end
end
