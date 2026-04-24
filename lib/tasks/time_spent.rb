# encoding: UTF-8

class TimeSpent
  def self.fix_course(course_id, dry_run)
    Course.find(course_id).sections.map do |section_id|
      self.fix_section(section_id, dry_run)
    end
  end

  def self.fix_section(section_id, dry_run)
    self.attempts(section_id).map do |attempt|
      time_spent = attempt.time_spent
      time_limit = attempt.time_limit

      # Calculates the difference between time spent and time limit,
      # then determines the whole number of hours within the difference,
      # and subtracts that from the time spent.
      fixed_time_spent = time_spent - (((time_spent - time_limit) / 3600).floor * 3600)

      attempt.time_spent = fixed_time_spent

      unless dry_run
        attempt.save
        attempt.propagate_time_spent_to_score
      end

      {
        id: attempt.id,
        time_spent: time_spent,
        fixed_time_spent: fixed_time_spent,
        time_limit: time_limit
      }
    end
  end

  def self.attempts(section_id)
    # This is broken up to support inline comments.

    # Select is required for readonly=>false
    # time_limit is stored in minutes.
    attempt = Attempt.select('attempts.*, (assigned_assessment_details.time_limit * 60) AS time_limit')
    attempt.joins('INNER JOIN activities ON activities.id = attempts.activity_id')
    attempt.joins('INNER JOIN assignments ON assignments.section_id = attempts.section_id')
    attempt.joins('INNER JOIN assigned_assessment_details ON assigned_assessment_details.assignment_id = assignments.id')
    attempt.where(section_id: section_id)
    # 2 = completed
    attempt.where('attempts.status_code = 2')
    attempt.where("assignments.assignable_type = 'Activity'")
    # Only affects assessments which are timed, even though we record the time spent
    # for every attempt.
    attempt.where('assigned_assessment_details.time_limit > 0')
    # Converts time_limit from minutes to seconds, and adds an extra minute for padding.
    #
    # Time spent reading instructions is added in addition to time spent during the attempt,
    # so the extra minute removes most results from people who took the entire time
    # and read the instructions.
    #
    # Adding the extra minute isn't entirely necessary, since our `fixed_time_spent`
    # calculation only looks at the difference between the time spent and the time limit.
    attempt.where('((assigned_assessment_details.time_limit * 60) + 60) < attempts.time_spent')
  end
end
