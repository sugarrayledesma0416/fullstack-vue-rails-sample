class CourseTimeCalculator
  def self.calculate(course)
    return { weeks: 0, days: 0} if course.nil?

    start_date = course.start_date
    end_date = course.end_date

    total_days = (end_date.to_date - start_date.to_date).to_i
    weeks = total_days / 7
    days = total_days % 7
    { weeks:, days: }
  end

  def self.formatted_time(course)
    parsed_data = calculate(course)

    formatted_weeks = "#{parsed_data[:weeks]} #{parsed_data[:weeks] == 1 ? 'week' : 'weeks'}"
    formatted_days = "#{parsed_data[:days]} #{parsed_data[:days] == 1 ? 'day' : 'days'}"

    { weeks: formatted_weeks, days: formatted_days }
  end
end
