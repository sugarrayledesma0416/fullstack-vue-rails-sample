class Student < User
  has_many :attempts, foreign_key: :user_id
  has_many :enrollments, foreign_key: :user_id
  has_many :sections, through: :enrollments
  has_many :student_spotcheck_counts, foreign_key: :user_id
  has_many :vocab_words, foreign_key: :user_id

  attr_accessor :my_current_section

  def self.find_by_ids(user_ids)
    where(id: user_ids).order('last_name, first_name ASC')
  end

  def self.enrolled_in_sections(sections)
    # include the enrollments so we have access to the matching enrollment
    # from the student object, not all the enrollments for the student
    includes(:enrollments).where(enrollments: { state: ['enrolled', 'marked_complete'], section_id: sections })
  end

  def self.enrolled_in_sections_user_ids_only(sections)
    joins(:enrollments).where(enrollments: { state: ['enrolled', 'marked_complete'], section_id: sections }).pluck('users.id')
  end

  def base_account_type
    'Student'
  end

  def old_viewable_section?(section)
    !section.archived? && section.closed? && enrolled_in?(section)
  end

  def enrolled_in?(section)
    enrollments.by_section(section).active_or_completed.any?
  end

  def active_enrollments(eager_load = nil)
    enrollments.active_in_open_course(eager_load)
  end

  def active_sections(eager_load = :section)
    active_enrollments(eager_load).map(&:section)
  end

  def active_enrollments_in_editable_courses(eager_load = nil)
    enrollments.active_in_editable_course(eager_load)
  end

  def active_sections_in_editable_courses(eager_load = :section)
    active_enrollments_in_editable_courses(eager_load).map(&:section)
  end

  def sufficient_access_for_course?(section)
    enrollments.by_section(section).active.sufficient_access.any?
  end

  def active_courses
    @active_courses ||= active_sections(eager_load = {:section => :course}).map(&:course).uniq
  end

  # generates a hash for pubnub consumption containing information
  # about the student and his/her associated course(s) and section(s)
  # This is intended to be sent to the browser and consumed by the chat app.
  # Courses for which chat is disabled are INCLUDED so we can display them
  # along with a tooltip explaining how to enable chat.
  def pubnub_client_roster
    pubnub_active_courses = active_courses.map do |course|
      pubnub_course_info(course, sections_by_course[course.id])
    end
    pubnub_client_roster_hash(pubnub_active_courses)
  end

  # Generates a hash for the pubnub grant endpoint containing information
  # about the student and sections in which he/she is actively enrolled.
  # Sections in courses for which chat is disabled are excluded.
  def pubnub_grants_roster
    sections_to_grant = active_courses.reject(&:chat_disabled?).flat_map do |course|
      sections_by_course[course.id]
    end
    pubnub_grants_hash(sections_to_grant)
  end

  def active_courses_pubnub_grants_roster
    sections_to_grant = active_courses.flat_map do |course|
      sections_by_course[course.id]
    end
    pubnub_grants_hash(sections_to_grant)
  end

  def sections_by_course
    @sections_by_course ||= active_sections.group_by(&:course_id)
  end

  def is_student?
    true
  end

  def active_section?(section)
    !(active_sections.detect { |_section| _section.id == section.id }.nil?)
  end

  def accessible_program?(program)
    !(programs.detect { |_program| _program.id == program.id }.nil?)
  end

  def is_dropped_from?(section)
    return true unless section
    enrollment = Enrollment.where(user_id: id, section_id: section.id).first
    return true unless enrollment
    enrollment.dropped?
  end

  def active_section_from_enrollments(sections_from_focus)
    enrolled_section_ids = enrollments.by_section(sections_from_focus).active_or_completed.map(&:section_id)
    sections_from_focus.detect{ |section| enrolled_section_ids.include?(section.id) }
  end

  def current_section_in_program(program, session = {})
    @current_section ||= {}

    unless @current_section[program.id]
      @current_section[program.id] = best_active_section(program, session)
    end

    @current_section[program.id]
  end

  private def best_active_section(program, session)
    potential_sections = active_sections.select do |section|
      section.program_id == program.id
    end

    return potential_sections.first if potential_sections.count < 2

    # raise ConcurrentSectionsError.new("Student: #{id}, Sections: #{sections.map(&:id)}")
    most_recent_id = session.dig(:most_recent_section, "program_#{program.id}")
    most_recent_section = most_recent_id && potential_sections.find do |section|
      section.id == most_recent_id
    end

    most_recent_section || potential_sections.first
  end

  # Edge case: This method will return nil when the instructor is grading
  # the course instead of the section.
  def most_relevant_section(sections)
    my_sections = active_or_completed_enrollments_in_editable_course_by_section(sections).map(&:section).uniq
    # raise ConcurrentSectionsError.new("Student: #{id}, Sections: #{my_sections.map(&:id)}") if my_sections.count > 1
    my_sections.first
  end

  def has_access_to_section_in_program?(section, program, session)
    section.section_zero? ||
      old_viewable_section?(section) ||
      (enrolled_in?(section) && section.program_id == program.id) ||
      # NOTE: This may not be needed. Keeping it to avoid potential regression.
      section == current_section_in_program(program, session)
  end

  def active_or_completed_enrollments_in_editable_course_by_section(sections)
    enrollments.active_or_completed_in_editable_course_by_section(sections)
  end
  private :active_or_completed_enrollments_in_editable_course_by_section

  def my_section_in(sections_list)
    section_ids = sections_list.collect(&:id)
    sections.each do |section|
      return section if section_ids.include?(section.id)
    end
    nil
  end

  def has_logged_in_within_last_one_month_and_is_active?
    return false unless active?
    return false unless last_login_at
    return false unless 1.months.ago < last_login_at
    true
  end

  def has_programs?
    (programs.count > 0)
  end

  def enrolled_in_section?(section)
    return false unless section

    # Differs from `#active_enrollment_by_section` because `#active_enrollments`
    # only returns enrollments for open courses and active sections. The result
    # should be the same unless there is a data corruption issue.
    !!active_enrollments.by_section(section).first
  end

  def has_attempts_in_section?(section)
    attempts_by_section(section).exists?
  end

  def attempts_by_section(section)
    attempts.by_section(section)
  end

  def active_enrollment_by_section(section)
    enrollments.active.by_section(section).first
  end

  def spotcheck_count
    return 0 unless  @my_current_section

    return @spot_check_count if defined?(@spot_check_count)

    student_spotcheck_counts.each do |check_count|
      return @spot_check_count = check_count.count if check_count.section_id == @my_current_section.id
    end
    return 0
  end

  def hashed_attempts
    hashed_attempts_unsorted = attempts.group_by(&:hash_key)
    hashed_attempts_unsorted.each do |attempt_key, attempts_array|
      hashed_attempts_unsorted[attempt_key] = attempts_array.sort {|a,b| b.attempt_number <=> a.attempt_number }
    end
    hashed_attempts_unsorted
  end

  def downloadable_resource(resource_id, program, section)
    if section && section.non_zero?
      program.find_student_resource_for_section(resource_id, section)
    else
      program.find_student_resource(resource_id)
    end
  end

  # Was the student active in a section during the 'editable' period?
  # We ask on behalf of the grading set -- we need to know after the course has ended
  # whether or not to show their gradeable activities.
  def active_in_editable_section?(sections)
    (active_sections_in_editable_courses & sections).present?
  end
end
