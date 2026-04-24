class StudentWork
  attr_accessor :user, :section, :activities, :work

  def initialize(user, section, activities)
    self.user = user
    self.section = section
    self.activities = activities
    self.work = activities.inject({}) { |h, activity| h[activity] = {} ; h }
  end

  def prepare
    assign_assignments
    assign_attempts
    self
  end

  def assignment_for(activity)
    work[activity][:assignment]
  end

  def latest_attempt_for(activity)
    if work[activity].has_key?(:attempts)
      work[activity][:attempts].first
    end
  end

  def assign_assignments
    Assignment.by_section_and_activity(section, activities).inject(@work) do |h, assignment|
      h[assignment.assignable].merge!(:assignment => assignment)
      h
    end
  end
  private :assign_assignments

  def assign_attempts
    Attempt.by_student_section_and_activity(user, section, activities).inject(@work) do |h, attempt|
      h[attempt.activity][:attempts] ||= []
      h[attempt.activity][:attempts] << attempt
      h
    end

    sort_attempts
  end
  private :assign_attempts

  def sort_attempts
    @work.values { |v| v[:attempts].to_a.sort! if v.has_key?(:attempts) }
  end
  private :sort_attempts
end
