class ActivityTimeSpentAverage
  # This is a Rails console command line tool
  # Given an activity type, it will gather up to 100,000 completed attempts
  # and calculate the average and a few percentiles of time spent on activities.
  # These values can help determine what default time estimate to use to set
  # 'minutes_to_complete' in an activity record. The default values are
  # stored in db/activity_time_estimates.yml.
  attr_accessor :activity_type, :sample_size, :min_time_spent, :desired_percentile

  def initialize(activity_type:, sample_size: 100_000, min_time_spent: 20, desired_percentile: 75)
    self.activity_type = activity_type
    self.sample_size = sample_size
    self.min_time_spent = min_time_spent
    self.desired_percentile = desired_percentile.to_f / 100
  end

  def calculate
    check_for_data

    if raw_attempts.count < sample_size
      puts "*** Sample less than requested: #{raw_attempts.count} < #{sample_size} ***"
    end

    puts "#{activity_type}: (based on #{filtered_time_spent.count} records)"
    puts "\tAverage: #{average_time_spent} minutes"
    [0.3, 0.5, desired_percentile, 0.9].each do |pct|
      pct_label = (pct * 100).to_i
      puts "\t#{pct_label}th percentile: "\
           "#{to_minutes(percentile(filtered_time_spent, pct))} minutes"
    end
    puts "\tMax: #{to_minutes(filtered_time_spent.max)} minutes"
  end

  def average_time_spent
    (filtered_time_spent.sum.to_f / filtered_time_spent.count / 60).round(2)
  end

  def activity_ids
    @activity_ids ||= Activity.where(activity_type: activity_type).pluck(:id)
  end

  def filtered_time_spent
    # remove attempts with time spent less than min_time_spent
    raw_attempts.select { |a| a.time_spent > min_time_spent }.map(&:time_spent)
  end

  private def raw_attempts
    @raw_attempts ||= Attempt.where(status_code: 2, activity_id: activity_ids).last(sample_size)
  end

  private def to_minutes(value, decimals = 2)
    (value / 60).round(decimals)
  end

  def percentile(values, pct)
    values_sorted = values.sort
    k = (pct * (values_sorted.length - 1) + 1).floor - 1
    f = (pct * (values_sorted.length - 1) + 1).modulo(1)

    values_sorted[k] + (f * (values_sorted[k + 1] - values_sorted[k]))
  end

  private def check_for_data
    raise StandardError, "No activity records found for activity type: #{activity_type}" unless activity_ids.any?
    raise StandardError, "No attempt records found for activity type: #{activity_type}" unless raw_attempts.any?
  end
end
