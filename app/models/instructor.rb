class Instructor < User
  include SectionInstructorArchiver

  MAX_PREVIEW_SECTIONS = 5

  # to ensure these methods are available, make sure to load using
  # Instructor.find instead of User.find

  has_one  :assignment_filter, foreign_key: :user_id
  has_many :announcements, foreign_key: :author_id
  has_many :courses,
           (lambda do
             where(is_demo: false, draft: false)
            .order('courses.name ASC, courses.start_date ASC')
           end),
           foreign_key: 'owner_id' do
    def open
      where('end_date >= ?', Time.zone.now.to_date)
    end
  end

  has_many :draft_courses, -> { where(is_demo: false, draft: true) },
           class_name: 'Course',
           foreign_key: 'owner_id'
  has_many :all_courses, -> { where(is_demo: false) },
           class_name: 'Course',
           foreign_key: 'owner_id'
  has_many :demo_courses, foreign_key: 'owner_id', class_name: 'DemoCourse'
  has_many :activity_notes, foreign_key: 'user_id'

  has_many :grading_sets, foreign_key: :user_id
  has_many :section_instructors, foreign_key: 'user_id'
  has_many :instructor_created_activities, foreign_key: 'instructor_id'
  has_many :sections, through: :section_instructors do
    def open
      includes(:course).where('courses.end_date >= ?', Time.zone.now.to_date)
                       .references(:courses)
    end

    def closed
      includes(:course).where('courses.end_date < ?', Time.zone.now.to_date)
                       .references(:courses)
    end

    def of_editable_courses_by_program(program)
      includes(:course).merge(Course.editable.where(program: program))
                       .references(:courses)
    end

    def of_open_courses_by_program(program)
      includes(:course).merge(Course.open.where(program: program))
                       .references(:courses)
    end
  end

  has_many :vocab_words, foreign_key: :user_id

  scope :by_school, (lambda do |*schools|
    includes(:school_users).references(:school_users)
    .where(
      'users.id = school_users.user_id  AND school_users.school_id in (?) ',
      schools
    )
  end)

  def base_account_type
    'Instructor'
  end

  def chat_sections
    sections.open.where(courses: { is_archived: false, is_demo: false })
  end

  def is_student?
    false
  end

  def gradeable_sections
    roles = [
      SectionInstructor::INSTRUCTOR_CREATOR_ROLES[:instructor],
      SectionInstructor::INSTRUCTOR_ROLES[:co_instructor],
      SectionInstructor::INSTRUCTOR_ROLES[:assistant]
    ]
    # We need to use compact here because the map can return an array with nil elements due to
    # archived sections.
    @gradeable_sections ||=
      section_instructors.where(role: roles).includes(:section).map(&:section).compact
  end

  def section_can_be_graded?(section_id)
    gradeable_sections.detect { |gradeable_section| gradeable_section.id == section_id }
  end

  def build_draft_course(program, school_id)
    complete_attributes = Course.default_values.merge('program_id' => program.id,
                                                      'school_id'  => school_id.to_i,
                                                      'first_unit_id' => program.units.first.id,
                                                      'last_unit_id' => program.units.last.id)
    self.draft_courses.build(complete_attributes)
  end

  def find_draft_course(course_id)
    course = all_courses.find(course_id)
    course.errors.add(:base, Course::EXPIRED_MESSAGE) unless course.draft?
    course
  end

  def find_or_create_draft_course(program, school_id, course_id = nil)
    if course_id.present?
      find_draft_course(course_id)
    else
      build_draft_course(program, school_id)
    end
  end

  def open_courses
    # open is defined on Kernel which causes this scope call to fail when you just do courses.open
    # see: https://github.com/rails/rails/issues/2508
    # using .scoped fixes this.  May want to look into how much it would suck to rename this scope.
    #
    # Update: we are still running into the clash with Kernel#open on Semaphore even with .scoped
    #   in place, so we're aliasing the scope in the Course model as a workaround.

    @open_courses ||= courses.open_course.includes(
      :program,
      :school,
      sections: { section_instructors: :instructor }
    )
  end

  # generates a hash for pubnub consumption containing information
  # about the instructor and his/her associated course(s) and section(s)
  # This is intended to be sent to the browser and consumed by the chat app.
  # Courses for which chat is disabled are INCLUDED so we can display them
  # along with a tooltip explaining how to enable chat.
  def pubnub_client_roster
    pubnub_client_roster_hash(pubnub_open_courses + pubnub_team_member_courses)
  end

  # Generates a hash for the pubnub grant endpoint containing information
  # about the instructor and sections he/she owns or is an instructor-team
  # member for.
  # Sections in courses for which chat is disabled are excluded.
  def pubnub_grants_roster
    sections_to_grant = chat_sections.where('courses.chat_level <> "disabled"')
    pubnub_grants_hash(sections_to_grant)
  end

  private def pubnub_open_courses
    Services::PubnubOpenCourses
      .new(self)
      .eligible_courses
      .map { |course| pubnub_course_info(course, course.sections) }
  end

  private def pubnub_team_member_courses
    group_data = show_sections_on_dashboard(team_member_sections).group_by(&:course)

    group_data.map do |course, sections|
      pubnub_course_info(course, sections)
    end
  end

  private def team_member_sections
    chat_sections.where(
      section_instructors: {
        role: [
          SectionInstructor::INSTRUCTOR_ROLES[:co_instructor],
          SectionInstructor::INSTRUCTOR_ROLES[:assistant]
        ]
      }
    )
  end

  private def show_sections_on_dashboard(sections)
    sections.includes(:section_instructors, :course, :current_students_base)
            .where(
              section_instructors: {
                hide_from_instructor_dashboard: false,
                user_id: id
              }
            )
            .where.not(
              'courses.is_enterprise = true AND ' \
              'courses.hide_from_instructor_dashboard = true AND ' \
              'courses.owner_id = ?',
              id
            )
  end

  def editable_courses
    courses.editable
  end

  def closed_courses
    courses.closed
  end

  def courses_by_school(school)
    courses.by_school(school)
  end

  def open_courses_by_school_and_program(school, program)
    open_courses.by_school(school).by_program(program)
  end

  def editable_courses_by_program(program)
    editable_courses.by_program(program)
  end

  def editable_courses_by_school_and_program(school, program)
    editable_courses_by_program(program).by_school(school)
  end

  def closed_courses_by_school_and_program(school, program)
    closed_courses.by_school(school).by_program(program)
  end

  def closed_courses_by_program_and_year(program, year)
    closed_courses.by_program(program).by_year(year)
  end

  # Given a program and year, return all closed courses for that combination,
  # as well as all sections that the instructor has access to.
  def closed_courses_by_program_and_year_with_owned_sections(program, year)
    # closed_sections uses the section_instructors join table

    sections = closed_sections.where(
      'courses.program_id = ? AND YEAR(courses.start_date) = ?',
      program.id,
      year
    ).references(:courses)
    courses = closed_courses_by_program_and_year(program, year)
    build_course_and_section_hash(courses, sections, program)
  end

  # Return all sections for an instructor based on the parent course's program.
  # Returns a scoped object for additional chaining.
  def sections_by_program(program)
    sections.joins(:course).where(courses: { program_id: program, is_archived: false } )
  end

  # Return all editable sections for an instructor for a given program
  # Returns a scoped object for additional chaining.
  def editable_sections_by_program(program)
    sections_by_program(program)
      .merge(Course.editable)
  end

  # Return all sections for an instructor based on the parent course's school and program affiliation.
  # Returns a scoped object for additional chaining.
  def sections_by_school_and_program(school, program)
    sections.joins(:course)
        .where(courses: { school_id: school, program_id: program, is_archived: false })
  end

  # Returns all editable sections for an instructor for a given school and program.
  # Returns a scoped object for additional chaining.
  def editable_sections_by_school_and_program(school, program)
    sections_by_school_and_program(school, program).where(
      ['courses.end_date >= ?', Time.zone.now.to_date - 1.month]
    ).where(courses: { is_template: false })
  end

  # Returns all closed sections for an instructor at a given school and program.
  # Returns a scoped object for additional chaining.
  def closed_sections_by_school_and_program(school, program)
    sections_by_school_and_program(school, program).where(['courses.end_date < ?', Time.zone.now.to_date])
  end

  # Returns all editable sections for a given school and program; eager loads course data.
  # Returns a scoped object for additional chaining.
  def editable_sections_by_school_and_program_with_courses(school, program)
    editable_sections_by_school_and_program(school, program).includes(:course)
  end

  # Returns all closed sections for a given school and program; eager loads course data.
  # Returns a scoped object for additional chaining.
  def closed_sections_by_school_and_program_with_courses(school, program)
    closed_sections_by_school_and_program(school, program).includes(:course)
  end

  # Given a program, returns all courses where the instructor has no sections.
  def editable_courses_without_sections_by_program(program)
    editable_courses_by_program(program)
      .joins('LEFT OUTER JOIN sections ON courses.id = sections.course_id AND sections.is_archived = 0')
      .where('sections.id IS NULL')
  end

  # This method returns all courses for a given school and program where the instructor
  # either has no sections or the course meets specific visibility rules:
  #
  # - Enterprise courses are included only if they are visible on the instructor dashboard.
  # - Non-enterprise courses are included only if they have no active sections
  #   and are visible on the instructor dashboard.
  #
  # The logic ensures that only relevant courses are displayed based on their type
  # (enterprise or non-enterprise) and visibility settings.
  def editable_courses_without_sections_by_school_and_program(school, program)
    editable_courses_by_school_and_program(school, program)
      .joins('LEFT OUTER JOIN sections ON courses.id = sections.course_id AND sections.is_archived = 0 AND sections.is_enterprise = 0')
      .where(
        <<~SQL
          (courses.is_enterprise = true AND courses.hide_from_instructor_dashboard = false) OR
          (sections.id IS NULL AND courses.is_enterprise = false AND courses.hide_from_instructor_dashboard = false)
        SQL
      )
  end

  def has_any_course_for?(program)
    sections.joins(:course)
        .where(courses: { program_id: program }).exists? || courses.by_program(program).exists?
  end

  def has_current_course_for?(program)
    open_courses.by_program(program).present?
  end

  def open_sections
    sections.open
  end

  def closed_sections
    sections.closed
  end

  def sections_of_editable_courses_by_program(program)
    sections.of_editable_courses_by_program(program)
  end

  def sections_of_open_courses_by_program(program)
    sections.of_open_courses_by_program(program)
  end

  def open_courses_for_program(program)
    courses.open_by_program(program)
  end

  def closed_courses_for_program(program)
    courses.closed_by_program(program)
  end

  def editable_courses_for_program(program)
    courses.editable_by_program(program)
  end

  # Return a hash that finds all instructor-accessible courses and sections
  # for the focus, restricted by school and program.
  def courses_and_sections_for_dashboard(school, program)
    sections = show_sections_on_dashboard(
      editable_sections_by_school_and_program_with_courses(
        school, program
      )
    ).includes(:section_instructors)
    courses = editable_courses_without_sections_by_school_and_program(
      school, program
    )
    build_course_and_section_hash(courses, sections, program)
  end

  # Return a hash that finds all instructor-accessible courses and sections
  # for the focus, restricted by program.
  def courses_and_sections_for_focus(program)
    sections = show_sections_on_dashboard(editable_sections_by_program(program))
               .includes(:course)
    courses = editable_courses_without_sections_by_program(program)
    build_course_and_section_hash(courses, sections, program)
  end

  # Return a hash where the keys are courses and the values are sections
  # that the instructor can access.
  def build_course_and_section_hash(courses, sections, program)
    hash = ActiveSupport::OrderedHash.new { |hsh, key| hsh[key] = [] }
    course_hash = sections.inject(hash) do |hsh, section|
      hsh[section.course] << section
      hsh
    end

    courses.each do |course|
      course_hash[course]
    end

    course_order_setting = setting("course_order_#{program.id}".to_sym)
    if course_order_setting.present?
      ordered_course_ids = course_order_setting.split(',').map(&:to_i)
      count = ordered_course_ids.count
      course_hash = Hash[course_hash.sort_by do |course, _sections|
        index = ordered_course_ids.index(course.id)
        index ? index : count
      end]
    end

    course_hash
  end
  private :build_course_and_section_hash

  def courses_for_program(program)
    courses.by_program(program).reorder('end_date DESC')
  end

  def all_sections_for_program(program)
    sections.joins(:course).where(courses: { program_id: program.id })
  end

  def courses_by_school_for_program(program)
    group_by_school(courses_for_program(program))
  end

  def open_courses_by_school_for_program(program)
    group_by_school(open_courses_for_program(program))
  end

  def closed_courses_by_school_for_program(program)
    group_by_school(closed_courses_for_program(program))
  end

  def most_recent_school_id
    unless courses.empty?
      return courses.sort_by(&:updated_at).reverse.first.school.id
    end
    unless schools.empty?
      SchoolUser.where(["user_id = #{id} and school_id IN (?)", schools.collect(&:id)])
          .sort_by(&:updated_at).reverse.first.school_id
    end
  end

  def fellow_instructor_ids
    SchoolUser.joins(:instructor)
        .where(school_id: schools, users: { archived: false })
        .pluck(:user_id)
        .reject { |instructor_id| instructor_id == id }
  end

  def sections_grouped_by_school_id(program)
    schools.inject({}) { |memo, school| memo[school.id] = editable_sections_by_school_and_program(school, program); memo }
  end

  def has_active_courses_for_program?(program_id)
    open_courses.each do |course|
      return true if course.program_id == program_id
    end
    false
  end

  def downloadable_resource(resource_id, program, _section = nil)
    program.resources.vhl_resource_or_uploaded_by_user(self).find(resource_id)
  end

  def demo_course_current?(program)
    section_up_to_date = false
    demo_courses.by_program(program).each do |course|
      course.sections.each do |section|
        section_up_to_date ||= section.current_upto.present?
      end
    end
    section_up_to_date
  end

  def igc(program)
    InstructorCreatedActivity.instructor(self).with_mapped_concept_in_program(program)
  end

  def has_igc?(program)
    igc(program).present?
  end

  # The presenter calls this to determine if there is IGC to be copied.
  def has_uncopied_igc_for_source_program?(destination_program)
    # look for a source program
    # return false if there isn't one
    source_program = ProgramToProgramMapping.source_program(destination_program)
    return false unless source_program

    # return false if user doesn't have igc
    return false unless has_igc?(source_program)

    # return false if all IGC for the source program is copied
    return false if has_copied_all_igc?(source_program, destination_program)

    # otherwise, there is still IGC to be copied: return true.
    true
  end

  def has_copied_all_igc?(program, destination_program)
    # Squawk if the instructor has no IGC. We should not call this method in that state.
    unless has_igc?(program)
      raise 'This method is invalid if the instructor has no IGC.'
    end

    igc_ids_to_copy(program, destination_program).empty?
  end

  def uncopied_igc_count(program, destination_program)
    igc_ids_to_copy(program, destination_program).size
  end

  def igc_ids_to_copy(program, destination_program)
    copy_job = IgcCopyJob.find_by(
      src_program_id: program.id,
      dest_program_id: destination_program.id,
      instructor_id: id
    )

    copied_ids = copy_job&.copied_ids || []

    # Get all IDs for IGC, then exclude anything that has been copied.
    igc(program).pluck(:id) - copied_ids
  end

  private

  def exclude_section(curr_section,
                      curr_section_list,
                      excluded_section_ids,
                      excluded_from_school_id)
    return true if curr_section.course.school.id == excluded_from_school_id &&
        excluded_section_ids.include?(curr_section.id)
    return true if curr_section_list.count >= MAX_PREVIEW_SECTIONS
    return true if (curr_section.course.school.id == excluded_from_school_id) &&
        ((excluded_section_ids.count + curr_section_list.count) >= MAX_PREVIEW_SECTIONS)
    false
  end

  def group_by_school(courses)
    courses_by_school = {}
    courses.each do |course|
      courses_by_school[course.school] = [] unless courses_by_school.key?(course.school)
      courses_by_school[course.school] << course
    end
    courses_by_school
  end
end
