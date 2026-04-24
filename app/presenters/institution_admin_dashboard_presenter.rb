class InstitutionAdminDashboardPresenter < SharedContentPresenter
  include GradebookHelper
  include Enterprise::DisplayableCourses

  attr_accessor :current_user
  attr_accessor :institution_admin
  attr_accessor :school
  attr_accessor :course
  attr_accessor :program
  attr_accessor :year

  def initialize(institution_admin, school_id = nil, program_id = nil, year = nil, course_id = nil)
    self.current_user = institution_admin
    self.institution_admin = institution_admin
    assign_school(school_id) if school_id
    assign_program(program_id) if program_id
    assign_course(course_id) if course_id
    @current_year = Time.zone.today.year
    self.year = year.presence.present? ? year.to_i : @current_year
  end

  def admin_program_options
    seen_programs = []

    current_user.admin_school_programs(school).each_with_object([]) do |program, result|
      program_title = program.title
      next if seen_programs.include?(program_title)

      seen_programs << program_title
      result << {
        program_id: program.id,
        school_id: school.id,
        program_title: program_title
      }
    end
  end

  def displayed_courses_by_school_program
    @displayed_courses_by_school_program ||= courses_by_school_selected_year
                                             .where(hidden_courses_for_user: { course_id: nil })
                                             .order('created_at DESC')
                                             .group_by(&:program_id)
  end

  def all_courses_grouped_by_program
    @all_courses_grouped_by_program ||= courses_by_school_selected_year
                                                   .order('created_at DESC')
                                                   .group_by(&:program_id)
  end

  def displayed_courses_by_school_program_non_enterprise
    @displayed_courses_by_school_program_non_enterprise ||= courses_by_school_selected_year_non_enterprise
                                                           .where(hidden_courses_for_user: { course_id: nil })
                                                           .order('created_at DESC')
                                                           .group_by(&:program_id)
  end

  def hidden_course_ids
    InstitutionAdminHiddenCourse.where(user_id: current_user.id).pluck(:course_id)
  end

  private def courses_by_school_selected_year
    if current_year_selected?
      courses_by_school_current_or_later_year
    else
      courses_by_school_and_year
    end
  end

  private def courses_by_school_selected_year_non_enterprise
    if current_year_selected?
      courses_by_school_current_or_later_year_non_enterprise
    else
      courses_by_school_and_year_non_enterprise
    end
  end

  # All courses completed during the selected year
  private def courses_by_school_and_year
    start_date = Date.new(year, 1, 1)
    end_date = Date.new(year, 12, 31)

    courses_by_school.where(courses: { end_date: start_date..end_date })
  end

  private def courses_by_school_and_year_non_enterprise
    start_date = Date.new(year, 1, 1)
    end_date = Date.new(year, 12, 31)

    courses_by_school_non_enterprise.where(courses: { end_date: start_date..end_date })
  end

  def course_order
    @course_order ||= current_user.setting("course_order_#{program.id}")
  end

  def hidden_courses(program_id)
    (hidden_courses_by_school_program_enterprise[program_id] || []) + (hidden_courses_by_school_program_non_enterprise[program_id] || [])
  end

  def hidden_courses_by_school_program_enterprise
    @hidden_courses_by_school_program_enterprise ||= courses_by_school
                                                      .where.not(hidden_courses_for_user: { course_id: nil })
                                                      .group_by(&:program_id)
  end

  def hidden_courses_by_school_program_non_enterprise
    @hidden_courses_by_school_program_non_enterprise ||= courses_by_school_non_enterprise
                                                          .where.not(hidden_courses_for_user: { course_id: nil })
                                                          .group_by(&:program_id)
  end

  def courses_by_school_program
    @courses_by_school_program ||= if course_order.present?
                                     Course.where(id: courses_by_school.collect(&:id) + courses_by_school_non_enterprise.collect(&:id))
                                     .open
                                     .order(Arel.sql("FIELD(id, #{course_order})"))
                                     .group_by(&:program_id)
                                   else
                                     Course.where(id: courses_by_school.collect(&:id) + courses_by_school_non_enterprise.collect(&:id))
                                     .open
                                     .order('created_at DESC')
                                     .group_by(&:program_id)
                                   end
  end

  def past_years_list
    @past_years_list ||= @current_year.downto(@current_year - 2).to_a
  end

  def courses
    (displayed_courses_by_school_program[program.id] || []) + (displayed_courses_by_school_program_non_enterprise[program.id] || [])
  end

  def all_courses
    courses + hidden_courses(program.id)
  end

  def all_courses
    all_courses_grouped_by_program[program.id] || []
  end

  def closed_courses
    (displayed_courses_by_school_program[program.id] || []).select{ |x| x.closed? }
  end

  def open_courses
    (displayed_courses_by_school_program[program.id] || []).select{ |x| x.open? }
  end

  def courses_non_enterprise
    displayed_courses_by_school_program_non_enterprise[program.id] || []
  end

  def closed_courses_non_enterprise
    courses_non_enterprise.select{ |x| x.closed? }
  end

  def open_courses_non_enterprise
    courses_non_enterprise.select{ |x| x.open? }
  end

  def sections(course_id = nil)
    return if course_id.nil?

    Course.find(course_id).sections.open.includes(:enrollments)
  end

  def section_owners(section)
    SortInstructorByRole.new(section).call
  end

  def past_sections(course_id = nil)
    return if course_id.nil?

    Course.find(course_id).sections.includes(:enrollments)
  end

  def count_enrollments_by_school_and_program(focus_school_id, program_id)
    @enrollments_by_school_and_program ||= enrollments_by_institution_admin(institution_admin)
                                           .where(courses: { is_template: false })
                                           .group(:school_id, :program_id)
                                           .count
    @enrollments_by_school_and_program[[focus_school_id, program_id]].to_i
  end

  def count_enrollments_by_course(course_id)
    @enrollments_by_course ||= enrollments_by_school(school.id).group(:course_id).count
    @enrollments_by_course[course_id].to_i
  end

  def count_enrollments_by_section(section_id)
    @enrollments_by_section ||= enrollments_by_school(school.id).group(:section_id).count
    @enrollments_by_section[section_id].to_i
  end

  def count_section_by_course(course_id)
    @section_by_course ||= Section.open.joins(:course)
                                  .where(courses: { school_id: school.id })
                                  .group(:course_id).count
    @section_by_course[course_id].to_i
  end

  def count_courses_by_program(focus_school_id, program_id)
    @courses_by_program ||= Course.open
                                  .where(school_id: institution_admin.admin_schools)
                                  .where('courses.end_date >= ?', Date.new(@current_year))
                                  .group(:school_id, :program_id).count

    @courses_by_program[[focus_school_id, program_id]].to_i
  end

  def count_section_by_program(focus_school_id, program_id)
    @section_by_program = Section.open.joins(:course)
                                 .where(courses: { school_id: institution_admin.admin_schools })
                                 .where(courses: { is_template: false  })
                                 .where('courses.end_date >= ?', Date.new(@current_year))
                                 .group(:school_id, :program_id)
                                 .count
    @section_by_program[[focus_school_id, program_id]].to_i
  end

  def count_section_by_district_and_program(district_id, program_id)
    district_schools_sum(district_id, program_id) do |school_id, program_id|
      count_section_by_program(school_id, program_id)
    end
  end

  def count_enrollments_by_district_and_program(district_id, program_id)
    district_schools_sum(district_id, program_id) do |school_id, program_id|
      count_enrollments_by_school_and_program(school_id, program_id)
    end
  end

  private def district_schools_sum(district_id, program_id)
    District.find(district_id).schools.sum do |school|
      yield(school.id, program_id)
    end
  end

  def section_needs_grading(section)
    student_ids = section.students.pluck(:id)
    task_list = ::InstructorGradingTasksPresenter.new(current_task: 'needs_grading_section',
                                                      section_ids: section.id,
                                                      student_ids: student_ids)
    task_list.tasklist_count('needs_grading_section')
  end

  def section_average(section)
    format_as_percent_with_one_decimal(
      GradebookEngine::GradebookAPI.section_average(section: section).to_f
    )
  end

  def count_insufficient_access_by_program(focus_school_id, program_id)
    @insufficient_access_by_program ||= enrollments_by_institution_admin(institution_admin)
                                        .where(enrollments: { sufficient_access: false })
                                        .group(:school_id, :program_id)
                                        .count
    @insufficient_access_by_program[[focus_school_id, program_id]].to_i
  end

  def count_insufficient_access_by_section(section_id)
    @insufficient_access_by_section ||= enrollments_by_school(school.id)
                                        .where(sections: { course_id: Section.find(section_id)
                                                                             .course_id })
                                        .where(enrollments: { sufficient_access: false })
                                        .group(:section_id)
                                        .count
    @insufficient_access_by_section[section_id].to_i
  end

  def section_insufficient_access(section_id)
    if count_insufficient_access_by_section(section_id).positive?
      link_to(
        count_insufficient_access_by_section(section_id),
        url_helpers.institution_admin_roster_dashboard_path(section_id, 'courses_past'),
        class: 'u-txt-black  u-txt-under'
      )
    else
      count_insufficient_access_by_section(section_id)
    end
  end

  def templates(program)
    templates_by_school_program[program]
  end

  def assign_school(school_id)
    self.school = School.find school_id
  end

  def assign_program(program_id)
    self.program = Program.find program_id
  end

  def assign_course(course_id)
    self.course = Course.find_by(id: course_id, is_enterprise: true)
  end

  def assign_req_params(req_params)
    @req_params = req_params
  end

  def count_idle_students_by_program(program_id, focus_school_id)
    courses_by_school_and_program(focus_school_id, program_id).inject(0) do |memo, course|
      course.sections.each do |section|
        memo += count_idle_students_by_section(section)
      end
      memo
    end
  end

  def count_idle_students_by_district_and_program(district_id, program_id)
    district_schools_sum(district_id, program_id) do |school_id, program_id|
      count_idle_students_by_program(program_id, school_id)
    end
  end

  # an idle student is defined as one who has not made an attempt in 10 days
  def count_idle_students_by_section(section)
    section_students = students_by_section(section)
    active_students = Attempt.where(section_id: section.id, user_id: section_students)
                             .group(:user_id)
                             .having('max(updated_at) >= ?', Time.zone.today - 10)
                             .select('user_id, max(updated_at)')
                             .pluck(:user_id)
    section_students.count - active_students.count
  end

  def duration_in_weeks_and_days(course)
    CourseTimeCalculator.calculate(course)
  end

  def count_pending_share_requests(focus_school_id, program_id)
    pending_share_requests_by_program[[focus_school_id, program_id]].to_i
  end

  def total_assignments_count(section)
    gb_section = GradebookEngine::Section.find(section.id)
    section.assignments.count + gb_section.external_assignments.count
  end

  def due_dates_count(section)
    # Find due dates for regular (m3) assignments.
    regular_due_dates = section.assignments
                               .group_by(&:due_date)
                               .keys

    # Find due dates for external assignments.
    external_due_dates = GradebookEngine::Section.find(section.id)
                                                 .external_assignments
                                                 .group_by(&:day_id)
                                                 .keys

    # Return the size of the union of the two sets.
    (regular_due_dates | external_due_dates).size
  end

  def students_by_section(section)
    section.enrollments.active_in_open_course.pluck(:user_id)
  end

  def avg_time_spent_per_student(section_id)
    params = { level: 'week',
               summary_level: 'section',
               summary_level_id: section_id,
               section_id: section_id }
    analytics = GradebookEngine::AnalyticsPresenter.new(params)
    analytics.overview_stats[:cumulative][:time_spent]
  end

  def instructor_full_name(instructor_id)
    User.find(instructor_id).full_name
  end

  # content page specific methods, views are shared between queue and library
  def strands(toc_entry = nil, all_lessons = false)
    if all_lessons
      @strands ||= program.strands
    elsif toc_entry.nil?
      display_lesson.strands(show_assessment_strands = true)
    else
      substrands_with_background(toc_entry.children, toc_entry.background_color)
    end
  end

  # need to gather activities for all lessons to show on the content queue page
  # if on queue page, "shared" will be false to get all pending requests
  # if on library page, "shared" will be true to get all approved requests
  def lesson_activities(shared)
    Activity.where(lesson_id: program.lessons)
            .joins(:shared_library_activities)
            .where(shared_library_activities: { school: current_user.admin_schools })
            .where(shared_library_activities: { is_shared: shared })
            .select('activities.*,' \
                    'max(shared_library_activities.id)')
            .group('activities.id')
  end

  def activities_by_toc_entry(is_shared, toc_entry)
    is_shared ? shared_activities(toc_entry) : unshared_activities(toc_entry)
  end

  private def activities_with_shared_library_records(shared:)
    SharedLibraryActivity
      .where(is_shared: shared, school: school)
      .where(activities: { lesson_id: program.lessons })
      .select('shared_library_activities.*')
      .select('max(shared_library_activities.id)')
      .group('activities.id')
  end

  private def unshared_activities(toc_entry)
    activities_with_shared_library_records(shared: false)
      .joins(:source_activity)
      .includes(:source_activity)
      .group_by do |shared_library_item|
        shared_library_item.source_activity.toc_location
      end[toc_entry.location.to_i] || []
  end

  private def shared_activities(toc_entry)
    activities_with_shared_library_records(shared: true)
      .joins([:activity, :source_activity])
      .includes([:activity, :source_activity])
      .group_by do |shared_library_item|
        shared_library_item.activity.toc_location
      end[toc_entry.location.to_i] || []
  end

  def activity_link(activity)
    link_to(activity.title, activity_path(activity), target: :_blank)
  end

  def course_template_options(program)
    Course.templates
          .where(end_date: (Time.zone.today + 1)..Float::INFINITY,
                 program: program,
                 school: school)
          .map do |course|
            [course.name, course.id]
          end
          .uniq
  end

  def course_owner_options(program)
    school.active_instructors_with_program_access(program)
          .order(:last_name, :first_name)
          .map { |instructor| ["#{instructor.full_name} (#{instructor.email})", instructor.id] }
  end

  def section_data(course_id)
    course = Course.find(course_id)
    owner_name = course.owner.last_name_first
    can_create_section = false
    if course.created_from_template?
      # Creating a section is OK if the source template exists and has "ready" sections.
      course_template = Course.templates.find_by(id: course.source_template_id)
      can_create_section = course_template.present? && course_template.sections.where(shared: 'true').exists?
    end
    add_section_snippet_state = can_create_section ? :default : 'disabled'
    data = {
      course_id: course_id,
      course_name: course.name,
      course_closed: course.closed?,
      owner_id: course.owner_id,
      owner_name: course.owner.last_name_first,
      created_from_template: course.created_from_template? && course.open?,
      edit_icon_snippet: Music::Components.icon(variant: 'edit'),
      add_section_snippet: Music::Components.button(
        text: Music::Components.icon(
                variant: 'add',
                text: 'Create Section',
                size: 'sm'
              ),
        variant: 'border',
        state: add_section_snippet_state,
        classes: ['u-mar-rt-0', 'js-create-section']
      ),
      can_create_section: can_create_section,
      alert_icon: feature_icon('music/icons/alert', ['c-embedded-icon--md']),
      no_sections: course.sections.count == 0,
      can_toggle_course_visibility: can_toggle_course_visibility(course),
      owned_by_current_user: course.owner == current_user,
      hide_from_inst_dash: course.hide_from_instructor_dashboard,
      owner_name_with_email: mail_to(course.owner.email, owner_name),

      source_template_id: course.source_template_id,
      total_enrolled: count_enrollments_by_course(course_id),
      total_sections: course.sections.count,
      sections_closed: section_row('past_sections', 'courses_past', course_id),
      sections: section_row('sections', 'courses', course_id)
    }

    merge_rails_env(data)
  end

  def enterprise_enrollment_count_with_link(section_id)
    enrollment_count_with_link(section_id, 'courses_past')
  end

  def section_metrics_data(section_id)
    section = Section.find(section_id)
    avg_time_spent = avg_time_spent_per_student(section_id)
    instructors = section.section_instructors_including_archived

    idle_students_with_link =
      (current_user.institution_admin?) ?
        link_to(count_idle_students_by_section(section),
                url_helpers.institution_admin_roster_dashboard_path(section.id, 'progress')) : count_idle_students_by_section(section)

    data = {
      course_id: section.course.id,
      course_name: section.course.name,
      section_id: section_id,
      section_name: section.name,
      section_average: section_average(section),
      avg_time_spent_per_student: "#{avg_time_spent[0]}hr #{avg_time_spent[1]}m",
      needs_grading: section_needs_grading(section),
      idle_students: count_idle_students_by_section(section),
      idle_students_with_link: idle_students_with_link,
      assignments: total_assignments_count(section),
      instructors: instructors.map { |instructor| instructor_data(instructor) },
      data_admin: current_user.data_admin?
    }

    merge_rails_env(data)
  end

  def hide_from_dash(course)
    # return false if the course has no sections or if the course owner is archived
    return false if course.sections.first.nil? || course.owner.archived?

    course.sections.first
          .section_instructors.where(role: 'Instructor').first
          .hide_from_instructor_dashboard
  end

  def course_owner_name(course)
    course.owner.full_name
  end

  def existing_section_names(course)
    course.sections.pluck(:name)
  end

  def section_template_options(course)
    course_template_id = course.source_template_id

    # Return an empty array unless the course has a source template that still exists.
    return [] unless course_template = Course.templates.find_by(id: course_template_id)

    #Returns only section templates mark as shared
    course_template.sections.select(&:shared?).map do |section|
      [section.name, section.id]
    end
  end

  def additional_instructor_options(course)
    all_instructors = school.active_instructors_with_program_access(course.program)
    (all_instructors - [course.owner]).map do |instructor|
      { id: instructor.id, full_name: instructor.full_name, email: instructor.email }
    end
  end

  def course_template_data(template)
    # If the course template has been deleted, include the 'template_deleted'
    # key as an easy way for the client to check whether there is anything to be
    # displayed.
    data = if template.nil?
             { template_deleted: true }
           else
             {
               categories: template.categories.map do |category|
                 {
                   name: category.name,
                   weighting_percent: category.weighting_percent
                 }
               end,
               create_section_template_snippet: Music::Components.button(
                 text: Music::Components.icon(
                         variant: 'add',
                         text: 'Create Section Template',
                         size: 'sm'
                       ),
                 variant: 'border',
                 classes: ['u-mar-rt-0', 'js-create-section-template']
               ),
               create_section_template_path: url_helpers
                 .institution_admin_new_section_template_path(
                   template.program.id,
                   template.id
                 ),
               end_date: template.end_date.strftime("%m/%d/%y"),
               links: {
                 'settings': [
                   { link: url_helpers.institution_admin_edit_course_template_path(
                       template.program_id,
                       template.school_id,
                       template.id
                     ),
                     text: 'Course Template Settings' }
                 ]
               },
               name: template.name,
               can_edit_course: template.owner == current_user,
               can_delete_course: (template.owner == current_user) && template.sections.empty?,
               program_id: program.id,
               remove_link: url_helpers.institution_admin_destroy_course_template_path(
                 template.program_id,
                 template.school_id,
                 template.id
               ),
               section_template_ids: template.sections.map(&:id),
               # FIXME: find right place for icon
               settings_icon: feature_icon('music/icons/instructor-dashboard/cog'),
               school_id: school.id,
               start_date: template.start_date.strftime("%m/%d/%y"),
             }
           end

    merge_rails_env(data)
  end

  def section_template_data(section_id)
    section_template = Section.find(section_id)
    first_lesson = section_template.lessons_covered.first
    first_activity_toc_location = first_lesson.activities.first.toc_location
    ready_for_share = section_template.shared
    data = {
      id: section_template.id,
      name: section_template.name,
      can_edit_section: section_template.instructor == current_user,
      assignment_count: total_assignments_count(section_template),
      assign_icon: Music::Components.icon(variant: 'add'),
      due_date_count: due_dates_count(section_template),
      ready: ready_for_share,
      links: {
        'assign': [
          { link: url_helpers.institution_admin_show_toc_template_path(
              program.id,
              section_template.course_id,
              section_id
            ),
            text: 'Activities' },
          { link: url_helpers.institution_admin_assessment_template_path(
              program.id,
              section_template.course_id,
              section_id,
              display_lesson: first_lesson.id,
              toc_location: first_activity_toc_location
            ),
            text: 'Assessments' },
          { link: url_helpers.institution_admin_new_assignment_template_path(
              program.id,
              section_template.course_id,
              section_id
            ),
            text: 'Start Assigning' },
          { link: url_helpers.institution_admin_assignment_template_path(
              program.id,
              section_template.course_id,
              section_id
            ),
            text: 'Assignment Calendar' },
          { link: url_helpers.institution_admin_assignment_wizard_template_path(
              program.id,
              section_template.course_id,
              section_id
            ),
            text: 'Assignment Wizard' },
          { link: url_helpers.institution_admin_external_item_template_path(
              program.id,
              section_template.course_id,
              section_id
            ),
            text: 'External Items' }
        ],
        'settings': [
          { link: url_helpers.institution_admin_edit_section_template_path(
              program.id,
              section_template.course_id,
              section_id
            ),
            text: 'Section Template Settings' }
        ]
      },
      remove_link: url_helpers.institution_admin_destroy_section_template_path(
        program.id,
        section_template.school_id,
        section_id
      ),
      settings_icon: feature_icon('music/icons/instructor-dashboard/cog'),
    }
    merge_rails_env(data)
  end

  def csv_filename
    "#{lower_and_hyphen(school.name)}-#{lower_and_hyphen(program.title)}-metrics.csv"
  end

  def set_return(origin, program_id, school_id, year = @current_year)
    possible_origins = {
      'courses' => url_helpers.institution_admin_courses_current_path(
        program_id: program_id,
        school_id: school_id
      ),
      'courses_past' => url_helpers.institution_admin_courses_past_path(
        program_id,
        school_id: school_id,
        year: year
      ),
      'progress' => url_helpers.institution_admin_section_metrics_path(
        program_id,
        school_id: school_id
      )
    }
    possible_origins[origin]
  end

  def current_year_selected?
    year >= @current_year
  end

  def selected_year_label
    year_label(year)
  end

  def current_past_select_options
    past_years_list.map do |year|
      yield(year, year_label(year), program.id, school.id)
    end
  end

  private def year_label(custom_year)
    custom_year >= @current_year ? 'Current' : custom_year
  end

  def section_additional_instructors(section)
    section.additional_instructors
        .map { |instructor| section_row_instructor_data(instructor) }
  end

  def section_edit_modal_data(section)
    { section: section.id,
      name: section.name,
      hide_owner_name: section.hide_owner_name?,
      days_to_show_assignment_due_date: section.days_to_show_assignment_due_date,
      open_to_students: section.open_to_students?,
      due_time: parse_due_time(section.due_time),
      time_zone: section.time_zone,
      instructor: {
        name: section.instructor.full_name,
        id: section.instructor.id,
        email: section.instructor.email
      },
      additional_instructors: section_additional_instructors(section)}.to_json
  end

  def parse_due_time(due_time)
    {
      hours: due_time.strftime('%-l').to_i,
      minutes: due_time.strftime('%M'),
      ampm: due_time.strftime('%p')
    }
  end

  def days_to_show_assignment_due_date_options
    other = (2..30).to_a.map { |days| ["#{days} days", days] }
    {
      'Frequently used': [['Always', ''], ['1 Week', 7], ['2 Weeks', 14]],
      Other: [['1 day', 1], *other]
    }
  end

  def school_time_zone
    school&.time_zone || Time.zone.name
  end

  def timezone_options_for_select
    us_zones = ActiveSupport::TimeZone.us_zones
    world_zones = ActiveSupport::TimeZone.all.reject do |tz|
      ActiveSupport::TimeZone.us_zones.include?(tz)
    end

    timezones = us_zones + world_zones
    timezones.map { |tz| ["(GMT#{tz.formatted_offset}) #{tz.name}", tz.name] }
  end

  def show_program_cover_images(program_ids)
    @show_program_cover_images ||= fetch_cover_image_urls(program_ids)
  end

  private def fetch_cover_image_urls(program_ids)
    return {} if program_ids.blank?

    url = URI.parse(build_cover_image_url(program_ids))
    http = Net::HTTP.new(url.host, url.port)
    if url.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
    request = Net::HTTP::Get.new(url)
    request['User-Agent'] = 'VHL'.freeze
    request['Accept'] = 'application/json'
    response = http.request(request)
    handle_cover_image_response(response)
  rescue StandardError => e
    Rails.logger.error("Exception while fetching cover images: #{e.message}")
    {}
  end

  private def build_cover_image_url(program_ids)
    query = URI.encode_www_form(program_ids: program_ids.join(','))
    "#{UA_URL}/enterprise/api/programs_cover_image_urls?#{query}"
  end

  private def handle_cover_image_response(response)
    if response.is_a?(Net::HTTPSuccess)
      response_data = JSON.parse(response.body)
      Rails.logger.debug("Fetched cover image data: #{response_data}")
      response_data['urls'] || {}
    else
      Rails.logger.error("Failed to fetch cover images: #{response.code} #{response.message}")
      {}
    end
  end

  private def lower_and_hyphen(str)
    str.downcase.gsub(/\s/, '-')
  end

  private def enrollments_by_institution_admin(institution_admin)
    Enrollment.active
              .joins(section: :course)
              .where(courses: { school: institution_admin.admin_schools })
              .where('courses.end_date >= ?', Date.new(@current_year))
              .merge(Course.open)
  end

  private def enrollments_by_school(school_id)
    Enrollment.active.joins(section: :course)
              .where(courses: { school_id: school_id })
  end

  private def courses_by_school_and_program(school_id, program_id)
    Course.open
          .where(school_id:, program_id:)
          .where('end_date >= ?', Date.new(@current_year))
  end

  private def templates_by_school_program
    @templates_by_school_program ||= school.courses.templates.order('created_at DESC').group_by(&:program)
  end

  private def enrollment_status_icon(section)
    locked_state = section.open_to_students? ? 'open' : 'closed'
    feature_icon("music/icons/lock-#{locked_state}")
  end

  private def url_helpers
    Rails.application.routes.url_helpers
  end

  private def merge_rails_env(hash)
    hash.merge(env: Rails.env)
  end

  private def section_row(state_method, origin, course = nil)
    send(state_method, course).map do |section|
      { additional_instructors: additional_instructors(section)
          .map { |instructor| section_row_instructor_data(instructor) },
        enrollment_count_with_link: enrollment_count_with_link(section.id, origin),
        enrollment_status_icon: enrollment_status_icon(section),
        id: section.id,
        insufficient_access_count: count_insufficient_access_by_section(section.id),
        name: section.name,
        show_owner: !section.hide_owner_name,
        source_template_id: section.source_template_id }
    end
  end

  private def instructor_data(instructor)
    {
      role: instructor.role,
      last_name: instructor.last_name,
      last_name_first_with_email: mail_to(instructor.email, instructor.last_name_first)
    }
  end

  private def section_row_instructor_data(instructor)
    {
      id: instructor.user_id,
      role: instructor.role,
      full_name: instructor.instructor.full_name,
      email: instructor.instructor.email,
      show: instructor.show
    }
  end

  private def pending_share_requests_by_program
    @pending_share_requests_by_program ||= begin
      SharedLibraryActivity
        .joins(%(LEFT OUTER JOIN activities
               ON activities.id = shared_library_activities.source_activity_id))
        .joins('LEFT OUTER JOIN concepts ON activities.concept_id = concepts.id')
        .where(is_shared: false)
        .group(['shared_library_activities.school_id', 'concepts.program_id'])
        .count
    end
  end

  private def can_toggle_course_visibility(course)
    course.owner == current_user && course.sections.count != 0 && course.open?
  end

  private def enrollment_count_with_link(section_id, origin)
    link_to(
      count_enrollments_by_section(section_id),
      url_helpers.institution_admin_roster_dashboard_path(section_id, origin),
      class: 'u-txt-black  u-txt-under'
    )
  end

  private def additional_instructors(section)
    section.section_instructors
           .joins(:instructor)
           .where("role != 'Instructor'")
           .order('role desc, users.last_name, users.first_name')
  end
end
