
class EventCalendar
  attr_accessor :messages

  def initialize(calendar_settings, target_month_date = nil)
    @event_months = Array.new
    @calendar_settings = calendar_settings
    @from_date = @calendar_settings.start_date
    @to_date = @calendar_settings.end_date
    @messages = []

    @target_month_date = target_month_date
    if @target_month_date
      if @target_month_date < @from_date
        @target_month_date = @from_date
      elsif @target_month_date > @to_date
        @target_month_date = @to_date
      end
      @event_months << EventMonth.new(@target_month_date, @calendar_settings)
    else
      @event_months << EventMonth.new(@from_date, @calendar_settings)
      until @event_months.last.contains?(@to_date) do
        @event_months << @event_months.last.next
      end
    end

    if @calendar_settings.type == 'course' && @calendar_settings.section_class_days_vary?
      @messages << "The course schedule varies by section. Select a section to view its schedule."
    end

    @first_month_index = month_index(@from_date)
    @category_ids = []
  end

  def month
    @target_month_date.month
  end

  def year
    @target_month_date.year
  end

  def beginning_of_month
    @target_month_date.beginning_of_month
  end

  def end_of_month
    @target_month_date.end_of_month
  end

  def <<(event)
    @category_ids << event.category_id if event.is_a?(Assignment) && !event.assignable.assessment?
    @event_months[0] << event
  end

  def populate_categories
    categories = Category.where(id: @category_ids.uniq).order(:rank)
    self.each_day do |day|
      day.update_categories(categories)
    end
  end

  def each_day(&block)
    each_week {|week| week.each(&block)}
  end

  def each_week(&block)
    each_month {|month| month.each_week(&block)}
  end

  def each_month
    @event_months.each {|month| yield(month)}
  end

  def each(&block)
    each_month {|month| month.each(&block)}
  end

  def empty?
    @event_months.empty?
  end

  def months
    @event_months
  end

  def prev_year_month
    year = @target_month_date.year
    month = @target_month_date.month
    new_date = Date.new(year.to_i, month.to_i, 1) - 1.month
    from_year_month = "%4d-%02d" % [@from_date.year, @from_date.month]
    prev_year_month = "%4d-%02d" % [new_date.year, new_date.month]
    prev_year_month if prev_year_month >= from_year_month
  end

  def next_year_month
    year = @target_month_date.year
    month = @target_month_date.month
    new_date = Date.new(year.to_i, month.to_i, 1) + 1.month
    to_year_month = "%4d-%02d" % [@to_date.year, @to_date.month]
    next_year_month = "%4d-%02d" % [new_date.year, new_date.month]
    next_year_month if next_year_month <= to_year_month
  end

  def this_year_month
    new_date = Time.zone.now.to_date
    from_year_month = "%4d-%02d" % [@from_date.year, @from_date.month]
    to_year_month = "%4d-%02d" % [@to_date.year, @to_date.month]
    this_year_month = "%4d-%02d" % [new_date.year, new_date.month]
    this_year_month if (this_year_month >= from_year_month) && (this_year_month <= to_year_month)
  end

  def days_of_week
    return ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
  end

  private

  def month_index(date)
    date.year*12+date.month-1
  end

end
