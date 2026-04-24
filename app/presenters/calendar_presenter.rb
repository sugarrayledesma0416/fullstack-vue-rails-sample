class CalendarPresenter
  include IndividualAssignmentQueryable

  INSTRUCTOR_ASSIGNMENT_SCOPE_TEMPLATE = <<~SQL.freeze
    assignments.due_date >= ? AND assignments.due_date <= ?
  SQL

  STUDENT_ASSIGNMENT_SCOPE_TEMPLATE = <<~SQL.freeze
    COALESCE(individual_assignments.due_date, assignments.due_date) >= ?
    AND
    COALESCE(individual_assignments.due_date, assignments.due_date) <= ?
  SQL

  STUDENT_ASSIGNMENT_SCOPE_SELECT = <<~SQL.freeze
    assignments.id,
    assignments.assignable_id,
    assignments.assignable_type,
    assignments.category_id,
    COALESCE(individual_assignments.due_date, assignments.due_date) as due_date
  SQL

  attr_reader :event_calendar, :calendar_settings
  attr_accessor :user

  class CalendarSettings
    attr_accessor :start_date, :end_date, :type, :sections, :class_days, :course, :user, :program
    attr_writer :section_class_days_vary
    delegate :vista_online_learning?, :supersite_junior?, to: :program

    def initialize(params)
      params.each do |key, assigned_value|
        instance_variable_set("@#{key}", assigned_value) unless assigned_value.nil?
      end
    end

    def section_class_days_vary?
      @section_class_days_vary
    end

    def is_instructor?
      @is_instructor
    end

    def clickable_category_links?
      is_instructor? || !(vista_online_learning? || supersite_junior?)
    end

    def category_link_params
      return {} unless defined?(@category_link_params)
      @category_link_params.clone
    end

    def category_html_options
      return {} unless defined?(@category_html_options)
      @category_html_options.clone
    end

    def assessment_link_params
      return {} unless defined?(@assessment_link_params)
      @assessment_link_params.clone
    end

    def assessment_html_options
      return {} unless defined?(@assessment_html_options)
      @assessment_html_options.clone
    end

    def section_count
      @section_count ||= sections.count
    end
  end

  def initialize(user, target_month_date, program, other_params = {})
    validate_params(other_params)
    @params = other_params
    @program = program
    self.user = user
    @calendar_settings = build_calendar_settings(other_params[:focus] || other_params[:section])
    @event_calendar = EventCalendar.new(calendar_settings, target_month_date)
  end

  def items_by_date
    return @items_by_date if defined?(@items_by_date)

    assignments = MonthlyAssignmentList.new(
      @event_calendar.month, @event_calendar.year, sections, user
    ).assignments

    @items_by_date = {
      assignments: assignments,
      announcements: announcements_by_calendar_day
    }
  end

  def announcement_sections
    user.instructor? ? @params[:focus].sections : [@params[:section]]
  end
  private :announcement_sections

  def announcements_by_calendar_day
    Announcement.by_month_and_calendar_day(announcement_sections, @event_calendar.month)
  end
  private :announcements_by_calendar_day

  def self.build(*params)
    new_obj = self.new(*params)
    new_obj.build_calendar
    new_obj
  end

  # TODO: can we push this down to the EventDay class?
  def activity_count_by_date(date)
    (@items_by_date[:assignments][date] && @items_by_date[:assignments][date].activity_count.to_i) || 0
  end

  # TODO: can we push this down to the EventDay class?
  def total_time_by_date(date)
    (@items_by_date[:assignments][date] && @items_by_date[:assignments][date].total_time.to_i) || 0
  end

  def total_activity_count(month)
    @total_activity_count ||= {}
    return @total_activity_count[month.month] ||= get_total_activity_count(month)
  end

  def get_total_activity_count(month)
    month.days.inject(0) { |sum, day| sum + activity_count_by_date(day.date) }
  end
  private :get_total_activity_count

  def total_time(month)
    @total_time ||= {}
    return @total_time[month.month] ||= get_total_time(month)
  end

  def get_total_time(month)
    month.days.inject(0) { |sum, day| sum + total_time_by_date(day.date) }
  end
  private :get_total_time

  def build_calendar(opts = {})
    build_assignments unless opts[:skip_assignments]
    @event_calendar.populate_categories
    self
  end

  def sections
    calendar_settings ? calendar_settings.sections : []
  end

  def show_estimated_times?
    user.instructor? || calendar_settings.course.show_estimated_times?
  end

  def has_multiple_due_dates?(date)
    user.instructor? && dates_with_multiple_due_dates.include?(date)
  end

  private def dates_with_multiple_due_dates
    # If a due date includes an assignment that is individually assigned on
    # other days, there must be an individual assignment for that due date
    # where the due date is not the same as the default due date. This query
    # looks for those individual assignments and returns the distinct default
    # due dates for their associated assignments.
    @dates_with_multiple_due_dates ||= \
      Assignment
      .joins(<<~SQL.freeze
        INNER JOIN individual_assignments ia
        ON assignments.assignable_id = ia.activity_id AND assignments.section_id = ia.section_id
      SQL
            )
      .select('assignments.due_date')
      .where('assignments.due_date != ia.due_date')
      .where(assignments: { section_id: sections.pluck(:id) })
      .pluck(:due_date)
      .uniq
  end

  private def build_assignments
    assignment_scope.each { |assignment| @event_calendar << assignment }
  end

  private def assignment_scope
    if user.student?
      apply_individual_assignment_filter(base_assignment_scope, user.id).select(
        STUDENT_ASSIGNMENT_SCOPE_SELECT
      )
    else
      base_assignment_scope
    end
  end

  # For students, the condition for which assignments fall into the
  # current month needs to reflect custom due dates for individual
  # assignments, if present.
  private def assignment_scope_condition_template
    if user.student?
      STUDENT_ASSIGNMENT_SCOPE_TEMPLATE
    else
      INSTRUCTOR_ASSIGNMENT_SCOPE_TEMPLATE
    end
  end

  private def base_assignment_scope
    Assignment.by_section(sections.map(&:id)).where(
      assignments: { assignable_type: 'Activity' }
    ).where(
      assignment_scope_condition_template,
      @event_calendar.beginning_of_month,
      @event_calendar.end_of_month
    ).includes(assignable: :concept)
  end

  private def validate_params(params)
    params_keys = params.keys
    include_focus = params_keys.include?(:focus)
    include_section = params_keys.include?(:section)

    raise ':focus must be an object of type Focus.' if include_focus && !params[:focus].is_a?(Focus)
    raise ':section must be an object of type Section.' if include_section && !params[:section].is_a?(Section)
    raise 'You can only specify a Section or Focus, but not both.' if include_focus && include_section
  end

  private def build_calendar_settings(focus_or_section)
    calendar_settings = nil
    target_user = user.instructor? ? user : focus_or_section.course.owner
    if focus_or_section.is_a?(Focus)
      calendar_settings = CalendarSettings.new(
        assessment_html_options: assessment_html_options,
        assessment_link_params: assessment_link_params,
        category_html_options: category_html_options,
        category_link_params: category_link_params,
        class_days: focus_or_section.class_days,
        course: focus_or_section.course,
        end_date: focus_or_section.course_end_date,
        is_instructor: user.instructor?,
        program: @program,
        section_class_days_vary: focus_or_section.course.section_class_days_vary?,
        sections: focus_or_section.sections,
        start_date: focus_or_section.course_start_date,
        type: focus_or_section.type,
        user: target_user
      )
    elsif focus_or_section.is_a?(Section)
      calendar_settings = CalendarSettings.new(
        assessment_html_options: assessment_html_options,
        assessment_link_params: assessment_link_params(focus_or_section),
        category_html_options: category_html_options,
        category_link_params: category_link_params(focus_or_section),
        class_days: focus_or_section.class_days.split(',').sort.uniq,
        course: focus_or_section.course,
        end_date: focus_or_section.course.end_date,
        is_instructor: user.instructor?,
        program: @program,
        section_class_days_vary: focus_or_section.course.section_class_days_vary?,
        sections: [focus_or_section],
        start_date: focus_or_section.course.start_date,
        type: 'section',
        user: target_user
      )
    end
    calendar_settings
  end

  private def category_link_params(section = nil)
    if user.instructor?
      {
        action: :index,
        controller: 'instructor/assignables',
        program_id: @program.id,
        source: 'calendar'
      }
    else
      {
        action: :show,
        assignment_day: nil,
        category_id: nil,
        controller: :worksets,
        full: 1,
        section_id: section.id
      }
    end
  end

  private def category_html_options
    if user.instructor?
      {
        onclick: '$(this).assignment_wizard(); return false;',
        title: 'Adjust due dates'
      }
    else
      { class: 'assignment_day_workset_link' }
    end
  end

  private def assessment_link_params(section = nil)
    if user.instructor?
      {
        action: :index,
        controller: 'instructor/assignables',
        method: 'get',
        program_id: @program.id,
        source: 'calendar'
      }
    else
      { controller: :activities, action: :show, section_id: section.id }
    end
  end

  private def assessment_html_options
    if user.instructor?
      {
        onclick: '$(this).assignment_wizard(); return false;',
        title: 'Adjust due dates'
      }
    else
      { class: 'assignment_day_workset_link' }
    end
  end
end
