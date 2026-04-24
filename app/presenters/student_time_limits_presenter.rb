class StudentTimeLimitsPresenter
  attr_accessor :errors

  def initialize(section_id:, activity_id:, time_limit: nil)
    @section_id = section_id
    @activity_id = activity_id
    @time_limits = time_limit
    @errors = {}
  end

  delegate :title, to: :activity, prefix: true
  delegate :time_limit, to: :assignment, prefix: true

  # process submitted data for setting and modifying time limits
  def process_time_limits
    @time_limits.each_key do |user_id|
      submitted_time_limit = @time_limits[user_id].strip

      case submitted_time_limit
      when ''
        remove_time_limit(user_id)
      when '0'
        set_unlimited_time_limit(user_id)
      else
        set_time_limit(user_id, submitted_time_limit)
      end
    end

    errors.empty?
  end

  private def remove_time_limit(user_id)
    student_time_limit(user_id).try(:delete)
  end

  private def set_unlimited_time_limit(user_id)
    set_time_limit(user_id, 0)
  end

  private def set_time_limit(user_id, new_time_limit)
    validate_time_limit(new_time_limit)
    validate_min_time_limit(new_time_limit)
    tl = student_time_limit(user_id)

    if tl.nil?
      AssessmentStudentTimeLimit.create!(
        user_id: user_id.to_i,
        section_id: section.id,
        activity_id: @activity_id,
        time_limit: new_time_limit.to_i
      )
    else
      tl.update!(time_limit: new_time_limit.to_i)
    end
  rescue StandardError => e
    @errors[user_id] = e.message
  end

  # returns an array of hashes used to populated the time limit form
  # all enrolled students are returned.
  # those without a custom time limit will have a nil value
  def student_time_limit_index
    limits = students.each_with_object([]) do |student, arr|
      arr << {}.tap do |hsh|
        hsh[:user_id] = student.id
        hsh[:name] = student.last_name_first
        hsh[:time_limit] = student_time_limit(student.id).try(:time_limit)
      end
    end
    limits.sort_by { |s| [(s[:time_limit] || 9999), s[:name]] }
  end

  # creates a lookup hash for students with existing custom time limits
  def student_time_limit(user_id)
    @student_time_limit ||= student_time_limits.each_with_object({}) do |stl, tlhash|
      tlhash[stl.user_id.to_s] = stl
    end
    @student_time_limit[user_id.to_s]
  end

  # This is probably a temporary method
  # used to show the current state of custom student time
  # limits after form data processing is complete
  def student_time_limit_updates
    # clear memoized values
    @student_time_limits = @student_time_limit = nil
    student_time_limit_index
  end

  def custom?(student)
    (student[:time_limit])&.positive?
  end

  def unlimited?(student)
    (student[:time_limit])&.zero?
  end

  def select_value(student)
    if custom?(student)
      'Custom'
    elsif unlimited?(student)
      'Unlimited'
    else
      'Default'
    end
  end

  # ensure time_limit value is valid
  # time_limit param must be a string
  private def validate_time_limit(time_limit)
    return unless time_limit =~ /\D/ # any non-digit character

    raise ArgumentError, 'Time limit must be a positive, whole number.'
  end

  private def validate_min_time_limit(time_limit)
    return unless time_limit == '1'

    raise ArgumentError, 'Time limit must be a minimum of 2 minutes.'
  end

  # get all time_limit records related to the section and activity
  private def student_time_limits
    @student_time_limits ||= ::AssessmentStudentTimeLimit.student_time_limits(section.id,
                                                                              activity.id)
  end

  private def section
    @section ||= Section.find(@section_id)
  end

  private def activity
    @activity ||= Activity.find(@activity_id)
  end

  private def assignment
    @assignment ||= Assignment.where(section_id: section.id,
                                     assignable_id: activity.id,
                                     assignable_type: 'Activity').first
  end

  private def students
    @students ||= section.current_students
  end
end
