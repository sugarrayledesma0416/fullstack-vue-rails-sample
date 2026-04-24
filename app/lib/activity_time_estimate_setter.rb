class ActivityTimeEstimateSetter
  def initialize(opts)
    @activity = opts[:activity]
    @activity_type = (opts[:activity_type] || @activity&.activity_type).downcase
    if (@activity || @activity_type).nil?
      raise ArgumentError, 'one of activity or activity_type required'
    end

    # if creating this object in a loop, call class#estimates outside
    # your loop and pass it in so you're not reading the file every time
    @estimates = opts[:estimates]
  end

  def apply
    raise ActiveRecord::ActiveRecordError, 'Activity object required' if @activity.nil?

    @activity.minutes_to_complete = time_to_complete
  end

  def update
    raise ActiveRecord::ActiveRecordError, 'Activity object required' if @activity.nil?
    raise ActiveRecord::ActiveRecordError, 'Cannot update new record' if @activity.new_record?

    # avoid callbacks which would try to set this value again
    @activity.update_column(:minutes_to_complete, time_to_complete) if needs_update?
  end

  def time_to_complete
    estimates[0]['base'][@activity_type] || 10
  end

  def needs_update?
    @activity.minutes_to_complete != time_to_complete
  end

  def self.estimates
    @estimates ||= YAML.load_file(Rails.root.join('db', 'activity_time_estimates.yml'))
  end

  def estimates
    self.class.estimates
  end
end
