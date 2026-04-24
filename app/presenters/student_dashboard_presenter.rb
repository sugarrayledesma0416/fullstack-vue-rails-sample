class StudentDashboardPresenter
  include Rails.application.routes.url_helpers
  include SectionDueDatesFinder

  attr_reader :pastdue_banks, :user, :section

  delegate :has_study_center?, to: :program, allow_nil: true
  delegate :program, to: :section, allow_nil: true

  def initialize(user, section)
    @user = user
    @section = section
  end

  def has_student_study_plans?
    UserReading.includes(recommendation: :study_plan_concept)
               .where(study_plan_concepts: { program_id: program.id })
               .where(user_id: user.id).exists?
  end

  def current_announcement_notifications
    section.current_announcement_notifications(user)
  end

  def notifications_list
    NotificationsPresenter.new(
      user, section, program
    ).notifications_and_announcements
  end

  def aggregate_assignment_days
    assignment_days = []
    assignment_days_creator = AssignmentDayCreator.new(user, section)
    if active_enrollment?
      pastdue_day = assignment_days_creator.create(current_due_day, pastdue = true)
      assignment_days << pastdue_day if pastdue_day
      next_assignment_days = find_next_assignment_days(current_due_day, 2)
      next_assignment_days.each_with_index do |day, index|
        show_expanded = (index == 0)
        due_day = assignment_days_creator.create(day, pastdue = false, show_expanded)
        assignment_days << due_day
      end
    end
    assignment_days
  end
  private :aggregate_assignment_days

  def active_enrollment?
    # Support showing instructors a preview of the student dashboard, by
    # always returning true of the user is an instructor.
    user.instructor? || section.open? && user.enrolled_in?(section)
  end

  def incomplete_due_dates_count
    @incomplete_due_dates_count ||= due_date_list.incomplete_due_dates_count
  end

  def due_date_list
    @due_date_list ||= DueDateList.new(user, section)
  end

  def past_assignment_summaries
    @past_assignment_summaries ||= due_date_list.past_assignment_summaries
  end

  def future_assignment_summaries
    @future_assignment_summaries ||= due_date_list.future_assignment_summaries
  end

  def incomplete_future_groups
    @incomplete_future_groups ||= future_assignment_summaries.flat_map do |summary|
      assignment_groups(summary).reject(&:complete?).each do |group|
        group.due_date = summary.due_date
      end
    end
  end

  def next_due_date
    @next_due_date ||= find_next_assignment_day
  end

  def next_due_date?(summary)
    next_due_date == summary.due_date
  end

  def past_assignment_summaries_url
    course_past_assignment_summaries_path(course_id: section.course_id, section_id: section.id)
  end

  def show_expanded?(summary)
    if summary.due_date < Date.today ||
       (summary.due_date == Date.today && section.date_in_past?(Time.zone.now))
      due_date_list.first_incomplete_past_due_date?(summary)
    else
      due_date_list.first_incomplete_future_due_date?(summary)
    end
  end

  def assignments_details_url(summary)
    course_assignments_by_due_date_path(
      course_id: section.course_id,
      due_date: summary.due_date,
      section_id: section.id
    )
  end

  def assignment_groups(summary)
    due_date_list.assignment_groups(summary)
  end

  def any_assignments?
    assignment_days.any?
  end

  def assignment_days
    @assignment_days ||= aggregate_assignment_days
  end

  def serialize_assignment_days
    AssignmentDayList.new(assignment_days).expand.map(&:serialize)
  end

  def gradesheet
    @gradesheet ||= GradebookEngine::GradebookAPI.student_gradesheet(
      section: section,
      user: user
    )
  end

  def program_language
    language_code = program&.language_code
    language_code && language_code != 'zh' ? language_code : 'en'
  end

  class AssignmentDayList
    attr_accessor :overdue_day, :first_due_day, :second_due_day

    def initialize(assignment_days)
      @all_due_days_completed = true
      assignment_days.each do |assignment_day|
        if assignment_day.overdue?
          self.overdue_day = assignment_day
        else
          if first_due_day
            self.second_due_day = assignment_day
          else
            self.first_due_day = assignment_day
          end
          @all_due_days_completed = @all_due_days_completed && assignment_day.all_assignments_completed?
        end
      end
    end

    def expand_overdue_day
      overdue_day.expanded = false if overdue_day
      overdue_day
    end
    private :expand_overdue_day

    def expand_first_day
      first_due_day.expanded = true if first_due_day
      first_due_day
    end
    private :expand_first_day

    def expand_second_day
      second_due_day.expanded = false if second_due_day
      second_due_day
    end
    private :expand_second_day

    def expand
      [expand_overdue_day, expand_first_day, expand_second_day].compact
    end
  end

  class AssignmentDay
    include ActionView::Helpers::TextHelper

    include Enumerable
    include DateTimeHelper

    attr_accessor :expanded
    attr_reader :due_date

    def initialize(section, due_date, banks, user, next_due_date = false)
      @section = section
      @due_date = due_date
      @bank_groups = []
      activity_banks = banks.reject(&:is_assessment)
      if activity_banks.present?
        @bank_groups << AssignmentBankGroup.new(
          section, activity_banks, user, @due_date
        )
      end
      banks.select(&:is_assessment).each do |bank|
        @bank_groups << AssignmentBankGroup.new(section, [bank], user, @due_date)
      end
      @next_due_date = next_due_date
    end

    def each
      @bank_groups.each { |group| yield group }
    end

    def overdue?
      @due_date == 'overdue'
    end

    def label
      if @due_date == 'overdue'
        'Overdue'
      else
        format_date_time(@due_date, _format = :weekday_month_ordinal)
      end
    end

    def all_assignments_completed?
      @bank_groups.empty?
    end

    def total_assignments
      @total_assignments ||= @bank_groups.sum(&:total_assignments)
    end

    def total_assignments_label
      total_assignments == 1 ? 'assignment' : 'assignments'
    end

    # Generate due_date sub-heading by combining the individual counts for singular_label
    private def due_date_sub_heading
      unit_count = @bank_groups.each_with_object(Hash.new(0)) do |bank_group, memo|
        memo[bank_group.unit_label] += bank_group.total_assignments
      end

      pluralized_labels = unit_count.each_with_object([]) do |(unit_label, count), memo|
        memo << pluralize(count, unit_label)
      end

      pluralized_labels.join(', ')
    end

    def serialize
      {
        label: label,
        expanded: expanded,
        overdue: overdue?,
        total_assignments: total_assignments,
        total_assignments_label: total_assignments_label,
        due_date: due_date,
        assignment_groups: serialize_bank_groups,
        all_assignments_completed: all_assignments_completed?,
        course_show_estimated_times: @section.course_show_estimated_times?,
        due_date_sub_heading: due_date_sub_heading
      }
    end

    private def serialize_bank_groups
      @bank_groups.map(&:serialize)
    end
  end

  class AssignmentDayCreator
    include IndividualAssignmentQueryable

    QUERY_OPTIONS = {
      assessment: { group_by: 'activities.id', is_assessment: 1 },
      activities: { group_by: 'concepts.id', is_assessment: 0 }
    }.freeze

    ASSIGNMENT_SELECT_STATEMENT = <<~SQL.squish.freeze
      lessons.label AS lesson_label,
      lessons.name AS lesson_name,
      lessons.rank AS lesson_rank,
      units.rank AS unit_rank,
      concepts.name AS concept_name,
      concepts.background_color AS background_color,
      concepts.assessment AS is_assessment,
      concepts.singular_label AS concept_unit_label,
      concepts.rank AS concept_rank,
      assignments.assignable_id AS assessment_id,
      assignments.show_at AS show_at,
      assignments.custom_due_time AS custom_due_time,
      activities.concept_rank AS activity_concept_rank,
      activities.toc_location_rank AS activity_toc_location_rank,
      COALESCE(asa.assignment_set_rank, assignments.rank) AS assignment_set_rank,
      COUNT(activities.id) AS activity_count,
      SUM(IFNULL(activities.minutes_to_complete, 10)) AS total_time
    SQL

    attr_reader :user, :section

    def initialize(user, section)
      @user = user
      @section = section
    end

    def create(date, pastdue, expanded = false)
      method_name = :find_a_days_banks
      method_name = :find_pastdue_banks if pastdue

      @results = send(method_name, :activities, date) +
                 send(method_name, :assessment, date)
      date = 'overdue' if pastdue

      if !pastdue || @results.length > 0
        banks = banks_params(pastdue).map do |bank_params|
          AssignmentBank.new(bank_params, section)
        end
        AssignmentDay.new(section, date, banks, user, expanded)
      else
        nil
      end
    end

    private def completed_and_submitted_attempts
      'LEFT JOIN attempts ON attempts.activity_id = activities.id ' \
        "AND attempts.user_id = #{user.id} " \
        'AND attempts.section_id = assignments.section_id ' \
        "AND attempts.status_code IN (#{AttemptStatus::CODE_SUBMITTED}, #{AttemptStatus::CODE_COMPLETED})"
    end

    def banks_params(pastdue)
      @results.each do |param|
        param.is_assessment = (param.is_assessment.to_s == '1')
        param.activity_count = param.activity_count.to_i
        param.total_time = param.total_time.to_i
        param.concept_unit_label = 'activity' if param.concept_unit_label.blank?
        param.show_at = param.show_at && Date.strptime(param.show_at.to_date.to_s) if pastdue
        param.assessment_id = param.assessment_id.to_i if param.assessment_id
      end
    end
    private :banks_params

    private def assignment_scope
      apply_individual_assignment_filter(
        Assignment.by_section(section).by_type(Activity).select(
          ASSIGNMENT_SELECT_STATEMENT
        ).joins(
          AssignmentSorter::ASSIGNMENT_JOINS
        ),
        user.id
      )
    end

    private def find_a_days_banks(type, due_day)
      joined_scope = assignment_scope.joins(
        completed_and_submitted_attempts
      ).where(
        [
          'COALESCE(individual_assignments.due_date, assignments.due_date) = ?',
          due_day
        ]
      ).where(attempts: { id: nil })
      apply_common_condition_and_group(joined_scope, type)
    end

    private def find_pastdue_banks(type, current_due_day)
      joined_scope = assignment_scope.joins(
        completed_and_submitted_attempts
      ).where(
        [
          'COALESCE(individual_assignments.due_date, assignments.due_date) < ?',
          current_due_day
        ]
      ).where(attempts: { id: nil })

      apply_common_condition_and_group(joined_scope, type)
    end

    private def apply_common_condition_and_group(scope, type)
      scope.where(
        concepts: { assessment: QUERY_OPTIONS[type][:is_assessment] }
      ).group(QUERY_OPTIONS[type][:group_by])
    end
  end

  class AssignmentBankGroup
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::TextHelper

    include Enumerable
    include ApplicationHelper

    attr_reader :unit_label

    def initialize(section, banks, user, due_date = nil)
      @section = section
      @banks = banks
      @due_date = due_date
      @user = user

      if @banks.any?
        @unit_label = @banks[0].concept_unit_label
        @is_released = @banks[0].is_released_assessment
        @assessment_id = @banks[0].assessment_id
        @is_assessment = @banks[0].is_assessment
        @due_time = @banks[0].custom_due_time
      else
        @unit_label = ''
      end
    end

    def each
      @banks.each { |bank| yield bank }
    end

    def total_time
      @banks.inject(0) { |sum, bank| sum + bank.total_time }
    end

    def total_assignments
      @total_assignments ||= @banks.inject(0) { |sum, bank| sum + bank.activity_count }
    end

    def total_label_pluralized
      label = pluralize(total_assignments, @unit_label)
      label.sub(/\d+\s/, '')
    end

    def can_be_started?
      !@is_assessment || @is_released
    end

    def start_path
      # Support showing instructors a preview of the student dashboard, but
      # with all the "Start" buttons for each workset disabled.
      if @user.instructor?
        '#'
      elsif @is_assessment
        section_activity_path(@section, @assessment_id)
      elsif @due_date
        section_assignment_day_path(@section, @due_date)
      else
        section_assignment_day_path(@section, 'pastdue')
      end
    end

    def due_time
      if @is_assessment
        assessment_due_time = @due_time
        assessment_due_time = Time.parse(assessment_due_time) if assessment_due_time.is_a?(String)
        assessment_due_time || @section.due_time
      else
        @section.due_time
      end
    end

    def time_zone
      return @section.time_zone unless Time.zone.name == @section.time_zone
    end

    def serialize
      {
        total_assignments: total_assignments,
        total_label_pluralized: total_label_pluralized,
        due_time: due_time.strftime("Due %I:%M %p"),
        time_zone: time_zone,
        estimate_time: format_hours_minutes(total_time, :short),
        url: start_path,
        can_be_started: can_be_started?,
        assignment_banks: serialize_banks
      }
    end

    private def serialize_banks
      # sort by assignment_set rank, assignment rank, unit rank, lesson rank,
      # concept rank, activity concept_rank and finally activity toc_location rank
      @banks.sort_by do |bank|
        [
          bank.assignment_set_rank,
          bank.unit_rank,
          bank.lesson_rank,
          bank.concept_rank,
          bank.activity_concept_rank,
          bank.activity_toc_location_rank
        ]
      end.map(&:serialize)
    end
  end

  class AssignmentBank
    include ActionView::Helpers::TextHelper
    include AudienceLabeling
    include DateTimeHelper

    attr_accessor :section

    attr_reader(
      :activity_count,
      :assessment_id,
      :availability_message,
      :background_color,
      :concept_name,
      :concept_rank,
      :concept_unit_label,
      :custom_due_time,
      :is_assessment,
      :is_released_assessment,
      :lesson_label,
      :lesson_rank,
      :total_time,
      :unit_rank,
      :assignment_set_rank,
      :activity_concept_rank,
      :activity_toc_location_rank
    )

    def initialize(query_results, section)
      self.section = section
      @lesson_label = query_results.lesson_label.presence || query_results.lesson_name
      @lesson_rank = query_results.lesson_rank
      @unit_rank = query_results.unit_rank
      @concept_rank = query_results.concept_rank
      @concept_name = query_results.concept_name
      @concept_unit_label = query_results.concept_unit_label
      @background_color = query_results.background_color
      @activity_count = query_results.activity_count
      @total_time = query_results.total_time
      @is_assessment = query_results.is_assessment
      @custom_due_time = query_results.custom_due_time
      @assignment_set_rank = query_results.assignment_set_rank
      @activity_concept_rank = query_results.activity_concept_rank
      @activity_toc_location_rank = query_results.activity_toc_location_rank
      if query_results.show_at
        @is_released_assessment = query_results.show_at < Time.zone.now.to_datetime
        if @is_released_assessment
          @availability_message = 'This assessment is available to start'
        else
          time_label = format_date_time(query_results.show_at, :time_with_zone, section.time_zone)
          @availability_message = "This assessment will be available on " \
                                  "#{format_date_time(query_results.show_at)} " \
                                  "at #{time_label}"
        end
      else
        @is_released_assessment = false
        @availability_message = 'This assessment will be available when ' \
                                "your #{instructor_label} releases it"
      end
      @assessment_id = query_results.assessment_id
    end

    private def instructor_label
      @instructor_label ||= audience_label(section&.program&.audience, :instructor)
    end

    def activity_count_text
      @is_assessment ? '' : pluralize(@activity_count, 'activity')
    end

    def serialize
      {
        background_color: background_color || '',
        lesson_label: lesson_label,
        concept_name: concept_name,
        assessment_id: assessment_id,
        availability_message: availability_message,
        activity_count_text: activity_count_text
      }
    end
  end
end
