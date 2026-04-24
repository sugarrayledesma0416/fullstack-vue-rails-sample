class InstructorDashboardPresenter
  include Instructor::DashboardHelper
  include CleverSectionLinks

  attr_accessor :instructor, :program, :focus

  delegate :help_request_count, :needy_student_count, :review_request_count,
           to: :unprocessed_request_counter
  delegate :course, :course_closed?, :course_open?, :sections,
           to: :focus, prefix: :focused

  def initialize(instructor, current_focus, opts = {})
    self.instructor = instructor
    self.program = Program.find(opts[:program_id])
    self.focus = current_focus
    @sections_data = {}
    @first_five_active_students = {}
    @student_access_problems = {}
  end

  def sections_data(section)
    @sections_data[section.id] ||= SectionData.new(
      section, grading_pending_scores[section.id] || []
    )
  end

  def instructor_schools
    (instructor.schools + editable_courses_by_program.map(&:school)).uniq
  end

  def enrollment_warning
    return @enrollment_warning if defined?(@enrollment_warning)

    schools_to_warn = instructor_schools.map do |school|
      school.name if seats_exhausted_for_school?(school)
    end.compact

    @enrollment_warning = unless schools_to_warn.empty?
                            'Your site license has no available seats<br/>'\
                              'for the following school(s):<br/>' +
                              format_as_list(schools_to_warn)
                          end
  end

  # rubocop:disable Rails/DynamicFindBy
  private def seats_exhausted_for_school?(school)
    site_license = Maestro::SiteLicense.find_by_program_and_school_or_district(
      program.id, school.guid, school.district&.guid
    )

    site_license.response.nil? ? false : site_license.hard_cap_reached
  end
  # rubocop:enable Rails/DynamicFindBy

  def open_courses_by_program
    @open_courses_by_program ||= instructor.open_courses_for_program(program)
  end

  def closed_courses_by_program
    instructor.closed_courses_for_program(program)
  end

  def open_courses_by_school(school)
    instructor.open_courses_by_school_and_program(school, program)
  end

  def closed_courses_by_school(school)
    instructor.closed_courses_by_school_and_program(school, program)
  end

  def editable_courses_and_sections_by_school(school)
    instructor.courses_and_sections_for_dashboard(school, program)
  end

  def assignment_wizard_enabled?(course)
    # if program is vol OR
    # there is a section with assignments OR
    # there is a section with external assignments
    program.vista_online_learning? ||
      has_ever_assigned_work?(course.school_id) ||
      GradebookEngine::GradebookAPI.has_external_assignments?(course.school_id,
                                                              instructor_sections.map(&:id))
  end

  def first_course_as_focus
    courses = open_courses_by_program
    courses.present? ? 'Course,' + courses.first.id.to_s : nil
  end

  def student_access_problem_count(section)
    student_access_problems(section).size
  end

  def first_five_active_students(section)
    section_id = section.id
    return @first_five_active_students[section_id] if @first_five_active_students[section_id]
    bad_access = student_access_problems(section)
    student_list = \
      (bad_access.size < 5 && section.first_five_active_students - bad_access) || []
    @first_five_active_students[section_id] = (
      StudentDecorator.decorate(bad_access, _access_problems = true) +
      StudentDecorator.decorate(student_list, _access_problems = false)
    )[0..4]
  end

  # Methods that use SectionData instances

  def activity_count_by_section(section)
    sections_data(section).activity_count
  end

  def score_count_by_section_and_activity_id(section, activity_id)
    sections_data(section).score_count_by_activity_id(activity_id)
  end

  def first_three_activity_scores(section)
    sections_data(section).unique_activity_scores[0..2]
  end

  # Methods that make use of StudentAssignmentMap data

  def unfinished_upcoming_assignments_by_section(section)
    count_students_by_assignment_status(section) do |assigned, completed|
      # no assignments done
      completed.zero? && assigned.nonzero?
    end
  end

  def finished_upcoming_assignments_by_section(section)
    count_students_by_assignment_status(section) do |assigned, completed|
      # all assignments done
      completed == assigned && assigned.nonzero?
    end
  end

  def partially_finished_upcoming_assignments_by_section(section)
    count_students_by_assignment_status(section) do |assigned, completed|
      # some assignments done
      completed.positive? && completed < assigned
    end
  end

  # Clever methods

  def clever_warning?
    clever_school_warning.required?
  end

  def clever_warning_message
    clever_school_warning.message
  end

  def clever_section_for(section)
    clever_section_links.dig(section.guid, 'clever_section_name')
  end

  def clever_section_linked?(section)
    clever_section_links.dig(section.guid, 'linked')
  end

  def clever_section_error?(section)
    clever_section_links.dig(section.guid, 'error')
  end

  # Determine if there is a dashboard announcement to show
  def dashboard_announcement
    if program.vista_online_learning
      DashboardAnnouncement.where(vol: true).first
    else
      DashboardAnnouncement.where(supersite: true).first
    end
  end

  def has_linked_rostering_user?
    has_one_roster_linked_user? || has_lti_roster_linked_user?
  end

  def has_one_roster_linked_user?
    instructor.one_roster_linked_user.present?
  end

  def has_lti_roster_linked_user?
    instructor.lti_rostering?
  end

  def course_creation_path(school)
    if instructor.one_roster_rostering?
      routes_helper.one_roster_instructor_courses_path(program)
    else
      routes_helper.instructor_new_course_path(program, school)
    end
  end

  # Only returns the sections that the instructor has access to.
  private def focused_course_sections_for_instructor
    @focused_course_sections_for_instructor ||= \
      focus.course&.sections_by_instructor(instructor) || []
  end
  alias sections focused_course_sections_for_instructor

  private def focused_course_section_ids_for_instructor
    @focused_course_section_ids_for_instructor ||= sections.map(&:id)
  end
  alias section_ids focused_course_section_ids_for_instructor

  private def unprocessed_request_counter
    return if section_ids.empty?
    @unprocessed_request_counter ||= UnprocessedRequestCounter.new(
      section_ids,
      Student.enrolled_in_sections_user_ids_only(section_ids)
    ).populate
  end

  private def grading_pending_scores
    return {} if section_ids.empty? || all_student_in_focus.empty?
    @section_scores ||= GradebookEngine::GradebookAPI.pending_grading_results(
      section_ids: section_ids, user_ids: all_student_in_focus.map(&:id)
    ).group_by(&:section_id)
  end

  private def all_student_in_focus
    return [] if section_ids.empty?
    @focused_students ||= current_students_by_section_id.values.flatten
  end

  private def current_students_by_section_id
    return {} if section_ids.empty?
    @current_students_by_section_id ||= \
      Student.select('users.*, enrollments.section_id').joins(:enrollments)
      .where(
        enrollments: { section_id: section_ids, state: %w[enrolled marked_complete] }
      ).group_by(&:section_id)
  end

  private def instructor_sections
    @instructor_sections ||= instructor.sections
                                       .joins(:course)
                                       .where(courses: {program_id: program})
  end

  # rubocop:disable Layout/MultilineMethodCallIndentation
  # until this bug is fixed https://github.com/bbatsov/rubocop/issues/4431
  private def has_ever_assigned_work?(school_id)
    Assignment.where(section_id: instructor_sections)
      .joins(section: :course)
      .where(courses: { program_id: program, school_id: school_id })
      .exists?
  end
  # rubocop:enable Layout/MultilineMethodCallIndentation

  private def student_access_problems(section)
    return @student_access_problems[section.id] if @student_access_problems[section.id]
    student_ids = section.enrollments_without_sufficient_access.map(&:user_id)
    @student_access_problems[section.id] = \
      Student.where(id: student_ids).order('last_name, first_name')
  end

  private def student_assignment_maps
    @student_assignment_maps ||= sections.each_with_object({}) do |section, memo|
      assignments = sections_data(section).next_due_date_assignments
      students = current_students_by_section_id[section.id] || []
      memo[section.id] = StudentAssignmentMap.new(section, students, assignments)
    end
  end

  private def count_students_by_assignment_status(section)
    status_map = student_assignment_maps[section.id]
    assignment_count = status_map.assignment_count
    student_assignment_counts = status_map.student_assignment_counts

    status_map.students.count do |student|
      yield assignment_count, student_assignment_counts[student.id]
    end
  end

  private def editable_courses_by_program
    instructor.editable_courses_by_program(program)
  end

  private def clever_school_warning
    @clever_school_warning ||= CleverSchoolWarning.new(instructor, instructor_schools)
  end

  private def routes_helper
    Rails.application.routes.url_helpers
  end

  module StudentDecorator
    attr_writer :access_problems

    def access_problems?
      @access_problems
    end

    def decorate(students, access_problems = false)
      students.each do |student|
        student.extend(StudentDecorator)
        student.access_problems = access_problems
      end
    end
    module_function :decorate
  end

  class SectionData
    NEXT_ASSIGNMENT_CONDITION = <<~SQL.freeze
      assignments.due_date > :date OR
      (
        assignments.due_date = :date AND
        COALESCE(custom_due_time, sections.due_time) > CAST(:time as time)
      )
    SQL

    attr_accessor :section, :scores

    delegate :program, :time_zone, :days_to_show_assignment_due_date, to: :section

    def initialize(section, scores = [])
      self.section = section
      self.scores = scores
    end

    def unique_activity_scores
      @unique_activity_scores ||= scores.uniq(&:activity_id)
    end

    def activity_count
      scores.filter do |score|
        !activity_has_individual_assignments?(score.activity_id, score.section_id) ||
          (activity_has_individual_assignments?(score.activity_id, score.section_id) &&
           individual_assignment_user_ids(score.activity_id, score.section_id)
          .include?(score.user_id))
      end.uniq(&:activity_id).count
    end

    def activity_has_individual_assignments?(activity_id, section_id)
      @activity_has_individual_assignments ||= IndividualAssignment.where(
        activity_id: activity_id, section_id: section_id
      ).present?
    end

    def individual_assignment_user_ids(activity_id, section_id)
      @individual_assignment_user_ids ||= IndividualAssignment.where(
        activity_id: activity_id, section_id: section_id
      ).pluck(:user_id).uniq
    end

    def score_count_by_activity_id(activity_id)
      @score_counts ||= scores.group_by(&:activity_id).tap do |memo|
        memo.each do |key, value|
          if activity_has_individual_assignments?(key, section.id)
            memo[key] = value.filter do |pending_scores|
              individual_assignment_user_ids(activity_id, section.id)
                .include?(pending_scores[:user_id])
            end.count
          else
            memo[key] = value.size
          end
        end
      end
      @score_counts[activity_id]
    end

    def next_assignment_due
      @next_assignment ||= first_assignment_due(section.today,
                                                section.now.strftime('%H:%M:%S')).first
    end

    def next_due_date_assignments
      @next_due_date_assignments ||= [] if next_assignment_due.nil?
      @next_due_date_assignments ||= section.assignments
                                            .due_on(next_assignment_due.due_date)
                                            .not_external
    end

    def due_date_scheduled?
      !section.days_to_show_assignment_due_date.nil?
    end

    # rubocop:disable Layout/MultilineMethodCallIndentation
    # until this bug is fixed https://github.com/bbatsov/rubocop/issues/4431
    private def first_assignment_due(date, time)
      Assignment.select('assignments.id, due_date, custom_due_time, section_id')
        .by_section(section)
        .not_external
        .joins(:section)
        .where(NEXT_ASSIGNMENT_CONDITION, date: date, time: time)
        .order(Arel.sql('due_date, COALESCE(custom_due_time, sections.due_time)'))
        .limit(1)
    end
    # rubocop:enable Layout/MultilineMethodCallIndentation
  end

  class CleverSchoolWarning
    MESSAGE_ENDING = 'now integrated with Clever. You may no longer create ' \
                     'courses using this account. Previous courses are still ' \
                     'viewable.'.freeze

    def initialize(instructor, instructor_schools)
      @instructor_schools = instructor_schools
      @instructor = instructor
    end

    # Determines if the Clever school warning is required.
    #
    # @return [Boolean] `true` if the instructor is (1) associated with Clever
    #                   schools, (2) is not a Clever user, and (3) has not
    #                   transitioned from Clever to LTI with rostering.
    #
    # NOTE: The check for Clever-to-LTI transitioning supports LTI rostering
    #       platforms with Clever filtering, which requires schools to keep
    #       their Clever IDs.
    def required?
      clever_schools.present? &&
        !@instructor.clever? &&
        !@instructor.lti_rostering_transitioned_from_clever?
    end

    def message
      return '' unless required?
      if clever_schools.count == 1
        singular_message
      else
        plural_message
      end
    end

    private def clever_schools
      @clever_schools ||= @instructor_schools.select(&:clever?)
    end

    private def singular_message
      "<b>#{clever_schools.first.name}</b> is " + MESSAGE_ENDING
    end

    private def plural_message
      clever_schools.map { |school| "<b>#{school.name}</b>" }.join(', ') +
      ': These schools are ' +
      MESSAGE_ENDING
    end
  end
end
