class PartnerChatRoster
  attr_reader :course, :activity, :user

  def initialize(user, course, activity)
    @user = user
    @course = course
    @activity = activity
  end

  def to_json
    { 'students_complete' => students_complete, 'students_incomplete' => students_incomplete }.to_json
  end

  def roster
   @roster_activity ||= (no_course? ? [] : roster_with_course)
  end

  def no_course?
     section_ids.blank?
  end
  private :no_course?

  def roster_with_course
    # All student id's from all the sections in the course who are currently enrolled
    # Also get the attempts status code if an attempt exists,
    # caring only for the completed attempt and returning nil for all other
    Student.find_by_sql(" select u.id as user_id,
                                a.status_code as attempt_status_code
                          from users u
                          inner join enrollments e
                          on e.user_id = u.id and
                             e.state = 'enrolled' and
                             e.section_id in (#{section_ids})
                          left outer join attempts a
                          on a.user_id = u.id and
                             a.section_id in (#{section_ids}) and
                             a.activity_id = #{activity.id} and
                             a.status_code in (#{AttemptStatus::CODE_COMPLETED})
                          where u.id <> #{user.id}")
  end
  private :roster_with_course

  def students_complete
    @students_complete ||= build_roster { |item| completed?(item.attempt_status_code) }
  end

  def students_incomplete
    # duplicates removal is required as duplicates could exist when an attempt was reset
    # remove the student from the incomplete students list if included in completed students list
    @students_incomplete ||= build_roster { |item| not_complete_and_not_reset?(item) }.uniq
  end

  def build_roster(&block)
    roster.select do |item|
      block.call(item)
    end.map(&:user_id)
  end
  private :build_roster

  def section_ids
    @section_ids ||= \
      if @user.instructor?
        @user.sections.open
             .where(courses: { program_id: @activity.program.id })
             .map(&:id).join(',')
      else
        course ? course.section_ids.join(',') : ''
      end
  end
  private :section_ids

  def completed?(key)
    key == AttemptStatus::CODE_COMPLETED
  end
  private :completed?

  def not_complete_and_not_reset?(item)
    !completed?(item.attempt_status_code) && !students_complete.include?(item.user_id)
  end
  private :not_complete_and_not_reset?
end
