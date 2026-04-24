class InstructorAssignablesPresenter

  include Rails.application.routes.url_helpers
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include ActionView::Helpers::TagHelper

  attr_accessor :assignables
  attr_reader :focus, :opts

  AVAILABILITY_OPTIONS = [
    ['when all students have been graded', :on_grading],
    ['when I release them', :on_release],
    ['after a specific date and time', :on_specific_date],
    ['after the due time', :on_due_date],
    ['never', :never]
  ].freeze
  EXCLUDED_ACTIVITY_TYPES = %w[
    virtual_chat partner_chat composition
  ].freeze

  def initialize(focus, opts = {})
    @focus = focus
    @opts = opts
    self.assignables = build_assignables
  end

  def already_assigned_count
    assignables.count(&:has_assignments?)
  end

  def assignables_count
    assignables.count
  end

  def individually_assignable_options
    if has_mixed_individually_assignable_status?
      [['varies', '']]
    else
      [['Entire Section', false], ['Individual Students', true]]
    end
  end

  def current_individually_assignable_value
    if has_mixed_individually_assignable_status?
      ''
    else
      first_assignable.individually_assignable
    end
  end

  def has_assignments_with_multiple_due_dates?
    assignables.any?(&:has_multiple_due_dates?)
  end

  def has_mixed_individually_assignable_status?
    any_individually_assignable_varies? ||
      assignables.have_different_values_for?(:individually_assignable)
  end

  def course_name
    focus.course_name
  end

  def section_names
    focus.section_names.join(', ')
  end

  def categories
    focus.course.categories
  end

  def track_group_names
    @track_group_names ||= TrackGroup.names_by_program(program)
  end

  def requires_track_group?
    for_vista_online_learning?
  end

  def program
    focus.program
  end

  def for_vista_online_learning?
    program.vista_online_learning
  end

  def current_track_group_name
    assignables_common_value_for(:track_group_name)
  end

  def current_category_id
    assignables_common_value_for(:category_id)
  end

  def assessment_release_status
    assignables_common_value_for(:show_assessment)
  end

  def assessment_grade_status
    grade_status = assignables_common_value_for(:grade_availability)
    if [nil, 'varies'].include? grade_status
      :on_grading
    else
      grade_status
    end
  end

  def assessment_release_date
    common_date_or_default(assignables_common_value_for(:show_at), "", :date_time_selector_format)
  end

  def assessment_grade_release_date
    common_date_or_default(assignables_common_value_for(:grades_available_at), "", :date_time_selector_format)
  end

  def assessment_answer_release_date
    common_date_or_default(assignables_common_value_for(:answers_available_at), "", :date_time_selector_format)
  end

  def program_id
    opts[:program_id]
  end

  def activity_ids
    opts[:activity_ids]
  end

  def resource_ids
    opts[:resource_ids]
  end

  def loaded_from
    opts[:source]
  end

  def in_institution_admin?
    opts[:in_institution_admin] == 'true'
  end

  def show_randomize_per_student_option?
    # To show this option, the program must be randomizable and at least one
    # activity must support randomization.
    program.allow_assessments_randomization? && assignables.any?(&:randomizable?)
  end

  def assessment_randomize_per_student
    assignables_common_value_for(:randomize_per_student)
  end

  def due_dates_for_sections
    return [] unless sections

    AssignmentSet.dates_for_sections(sections)
  end

  def sections
    focus.sections
  end
  private :sections

  def preferred_assignment_date
    opts[:preferred_assignment_date]
  end

  private def any_individually_assignable_varies?
    assignables.any? do |assignable|
      assignable.individually_assignable == 'varies'
    end
  end

  def first_assignable
    @first_assignable ||= assignables.first
  end
  private :first_assignable

  # We assume that all assignments have the same password.
  def first_assignment
    @first_assignment ||= first_assignable && first_assignable.assignments.first
  end
  private :first_assignment

  def assigned_assessment_detail
    @assigned_assessment_detail ||= first_assignment && first_assignment.assigned_assessment_detail
  end
  private :assigned_assessment_detail

  def assessment_password
    assigned_assessment_detail && assigned_assessment_detail.password
  end

  def assessment_number_of_attempts
    assigned_assessment_detail && assigned_assessment_detail.number_of_attempts
  end

  def attempts_overridable?
    assignables.all? do |activity|
      EXCLUDED_ACTIVITY_TYPES.exclude?(activity.activity_type) && !activity.instructor_graded?
    end
  end

  def number_of_attempts_warning
    "Activities of type #{EXCLUDED_ACTIVITY_TYPES.to_sentence.humanize.downcase} can only support one attempt." unless attempts_overridable?
  end

  def sentence_text_with_singular_label(field)
    case field
    when :show_assessment then "The #{assessment_label} will be hidden until"
    when :custom_due_time then "The #{assessment_label} will be due at"
    when :time_limit then "Set a time limit (minutes)"
    when :password then "Set a password"
    end
  end

  def assessment_release_status_text
    return 'I release it' if assessment_release_status.blank? || assessment_release_status == 'varies'
    if assessment_release_status == 'a specific date and time'
      common_date_or_default(assignables_common_value_for(:show_at), 'I release it')
    else
      assessment_release_status
    end
  end

  def assessment_grade_status_text
    return 'when I release them' if assessment_grade_status.blank? || assessment_grade_status == 'varies'
    case assessment_grade_status
    when :on_specific_date
      common_date_or_default(assignables_common_value_for(:grades_available_at), 'when I release them')
    when :on_due_date
      common_date_or_default(assignables_common_value_for(:due_date), 'when I release them')
    else
      availability_option_label(assessment_grade_status)
    end
  end

  def update_assignments_path
    if assignable_types_vary?
      raise IllegalMixingAssignableTypes, 'unable to assign both activities and resources at the same time'
    end

    return update_activity_assignments_path(program_id) if assigning_activities?
    return update_resource_assignments_path(:program_id => program_id) if assigning_resources?
  end

  def pluralized_assignable_type(count)
    type_name = if has_same_singular_label? && assignables.first.assignable_label.present?
                  assignables.first.assignable_label
                else
                  assignable_type
                end

    pluralize(count, type_name).gsub(/^\d+\s/, '')
  end

  def has_preferred_assignment_date?
    !preferred_assignment_date.blank?
  end

  def assignment_due_date
    due_date = assignables_common_value_for(:due_date)
    due_date = preferred_assignment_date if has_preferred_assignment_date? && due_date == ""
    common_date_or_default(due_date, "", :short)
  end

  def current_due_time
    current_due_time = assignables_common_value_for(:due_time)
    if current_due_time.is_a?(Time)
      current_due_time
    else
      focus.section.due_time
    end
  end

  def current_due_time_text
    #assignment custom due time is hr:min:ampm without any reference to time zone
    current_due_time.strftime('%l:%M %p').html_safe
  end

  def current_time_limit
    limits = assignables.flat_map(&:assignments).map { |a|
      if a.assigned_assessment_detail
        a.assigned_assessment_detail.time_limit
      else
        0
      end
    }
    (limits.empty? || limits.vary?) ? 0 : limits[0]
  end

  def group_chat_config
    assignables.each do |assignable|
      return assignable.group_chat_config if assignable.group_chat?
    end
  end

  def assignables_common_value_for(attribute)
    return nil if assignables.have_different_values_for?(attribute)
    assignables.first.send(attribute)
  end
  private :assignables_common_value_for

  def assessment_label
    label = assignables_common_value_for(:assignable_label)
    if has_same_singular_label? && label
      label
    else
      "assessment"
    end
  end
  private :assessment_label

  def has_same_singular_label?
    !assignable_types_vary? && assigning_activities? && !assignables.have_different_values_for?(:assignable_label)
  end
  private :has_same_singular_label?

  def common_date_or_default(current_value, default, date_format = :abr_weekday_month_ordinal_with_time)
    if [nil, 'varies'].include? current_value
      default
    else
      format_date_time(current_value, date_format, reference_section.time_zone)
    end
  end
  private :common_date_or_default

  def reference_section
    sections.first
  end

  def assignable_type
    assignables.first.class_name
  end
  private :assignable_type

  def assignable_types_vary?
    !assignables.collect(&:class_name).all_same?
  end
  private :assignable_types_vary?

  def assigning_activities?
    assignables.first.activity?
  end
  private :assigning_activities?

  def assigning_resources?
    assignables.first.resource?
  end
  private :assigning_resources?

  def has_assessments?
    assignables.detect {|assignable| assignable.assessment?}
  end

  def assessment_grade_availability_options
    AVAILABILITY_OPTIONS
  end

  def start_on_review_step?
    any_activities_already_assigned?
  end

  def start_on_reassign_step?
    !any_activities_already_assigned?
  end

  def any_activities_already_assigned?
    assignables.any? do |assignable|
      assignable.has_assignments?
    end
  end

  def group_chat_activities_count
    assignables.select(&:group_chat?).count
  end

  def refine_selection?
    loaded_from == 'calendar'
  end

  def selected_activity_ids
    selected_assignable_ids('activity')
  end

  def selected_resource_ids
    selected_assignable_ids('resource')
  end

  def selected_assignable_ids(class_name)
    assignables.collect do |assignable|
      assignable.id if assignable.class_name == class_name
    end.join(',')
  end
  private :selected_assignable_ids

  def build_assignables
    # We don't lookup activities with Services::TocActivityList here because the activity_ids come from the ToC,
    # and ToC display already is using Services::TocActivityList for lookup.
    assignables = Activity.where(id: activity_ids).joins(
      "LEFT OUTER JOIN assignments ON assignments.assignable_id = activities.id \
      AND assignments.section_id = #{focus.section.id} \
      AND assignments.assignable_type = 'Activity'"
    ).joins(
      AssignmentSorter::ASSIGNMENT_JOINS
    ).includes(
      :assignments,
      :lesson
    ).select(
      # Provide 0 as a default effective rank for activities that have not been assigned.
      # This is necessary to avoid comparing an integer to `nil` in `sort_by(&:effective_rank)`.
      'activities.*, COALESCE(asa.assignment_set_rank, assignments.rank, 0) as effective_rank'
    ).order(
      Arel.sql(AssignmentSorter::ASSIGNMENT_ORDER)
    ).sort_by(&:effective_rank)

    assignments_by_assignable = Assignment.by_activities_and_sections(assignables, focus.sections).group_by(&:assignable)
    assignables.each_with_object([]) do |assignable, memo|
      memo << Assignable.new(
        assignable,
        assignments_by_assignable[assignable],
        focused_on_only_one_section: focus.focused_on_only_one_section?,
        sections: focus.sections
      )
    end.flatten
  end
  private :build_assignables

  def assignments_for_assignable(assignable)
    Assignment.by_activities_and_sections(assignable, sections)
  end
  private :assignments_for_assignable

  def activities
    Activity.where(id: activity_ids)
            .joins("LEFT OUTER JOIN assignments ON assignments.assignable_id = activities.id \
                                AND assignments.section_id IN (#{section_ids}) \
                                AND assignments.assignable_type = 'Activity'")
            .order('assignments.rank ASC, activities.toc_location_rank ASC')
            .distinct
  end
  private :activities

  def resources
    Resource.find(resource_ids)
  end
  private :resources

  def section_ids
    sections.map(&:id).join(', ')
  end
  private :section_ids

  def availability_option_label(status)
    labels_by_option = Hash[AVAILABILITY_OPTIONS].invert
    labels_by_option[status]
  end
  private :availability_option_label

  class Assignable
    include ApplicationHelper
    include ActionView::Helpers::TagHelper

    attr_accessor :assignable, :assignments, :focused_on_only_one_section,
                  :sections

    delegate :activity_type, :icon, :id, :instructor_graded?, :randomizable?,
             :strand_and_title_label, :title,
             to: :assignable

    def initialize(assignable, assignments = [], opts ={})
      self.assignable = assignable
      self.assignments = assignments || []
      self.focused_on_only_one_section = opts[:focused_on_only_one_section] || false
      self.sections = opts[:sections] || []
    end

    def assignable_label
      assignable.respond_to?(:strand_singular_label) ? assignable.strand_singular_label : nil
    end

    COMMON_VALUE_ATTRIBUTES = %i[
      show_assessment
      show_at
      grade_availability
      grades_available_at
      category_id
      track_group_id
      due_date
      due_time
      time_limit
      password
      randomize_per_student
    ].freeze

    COMMON_VALUE_ATTRIBUTES.each do |attribute|
      define_method(attribute) do
        assignments_common_value_for(attribute)
      end
    end

    # Cache the value to avoid the repeating expensive calculation.
    def individually_assignable
      return @individually_assignable if defined?(@individually_assignable)

      @individually_assignable = calculate_individually_assignable
    end

    # The value for individually_assignable is a little different
    # from other attributes, as the absence of a value should be
    # considered the same as false.
    # Therefore, if some sections have assignments where the attribute
    # is false, and other sections have no assignments, the value should
    # not be considered to vary among sections.
    private def calculate_individually_assignable
      # If there are no assignments, consider the value to be false.
      return false if assignments.empty?

      if assignments.size == sections.size
        # If all sections have an assignment, the value will be true if
        # all sections are true, false if all sections are false, and
        # varies if any section has a different value than any other.
        assignments_common_value_for(:individually_assignable)
      elsif assignments.any?(&:individually_assignable)
        # If some sections have assignments and others don't, the value
        # will be varies if any section with an assignment has a true
        # value, as the sections without assignments should be considered
        # to be false.
        'varies'
      else
        false
      end
    end

    def class_name
      assignable.class.to_s.underscore
    end

    def assignment_ids
      assignments.collect(&:id).join(',')
    end

    def has_assignments?
      assignments.present?
    end

    def group_chat?
      assignable.activity_type == 'group_chat'
    end

    def group_chat_config
      gchat_assignment_config = assignments.first&.group_chat_assignment_config
      if !gchat_assignment_config.nil? && same_group_chat_config?
        {
          group_minimum: gchat_assignment_config.group_minimum,
          group_maximum: gchat_assignment_config.group_maximum
        }
      else
        {
          group_minimum: assignable.content_object.min_students_selection + 1,
          group_maximum: assignable.content_object.max_students_selection + 1
        }
      end
    end

    def activity?
      class_name == 'activity'
    end

    def category_name
      return '' if assignments.empty?
      return 'varies' if assignments_vary_by_category?
      assignments.first.category.name
    end

    def track_group_name
      return '' if assignments.empty?
      return 'varies' if assignments_vary_by_track_group_name?
      assignments.first.track_group_name || ''
    end

    def due_date
      return '' if assignments.empty?
      return 'varies' if assignments_vary_by_due_date?
      assignments.first.due_date
    end

    def toc_formatted_due_date
      if due_date.blank? || due_date == 'varies'
        due_date
      else
        format_date_time(due_date, :toc_due_date)
      end
    end

    def unassigned_sections
      @unassigned_sections ||= (assignments.first.all_sections_in_course - assignments.collect(&:section))
    end

    def resource?
      class_name == 'resource'
    end

    def assessment?
      assignable.respond_to?(:assessment?) && assignable.assessment?
    end

    def name
      [assignable.class.to_s.underscore, assignable.id].join('_')
    end

    def assignments_vary_by_due_date?
      different_assignment_counts_by_section? || varying_due_dates?
    end

    def assignments_vary_by_track_group_name?
      different_assignment_counts_by_section? || varying_track_group_names?
    end

    def assignments_vary_by_category?
      different_assignment_counts_by_section? || varying_categories?
    end

    def assignments_vary_by_section?
      different_assignment_counts_by_section? || varying_due_dates? || varying_categories?  || varying_track_group_names?
    end

    def different_assignment_counts_by_section?
      return false if focused_on_only_one_section
      assignments.any? { |assignment| assignment.sections_in_course_count != assignments.count }
    end

    def has_multiple_due_dates?
      assignments.any?(&:has_multiple_due_dates?)
    end

    def assignments_common_value_for(attribute)
      if assignments.empty?
        nil
      elsif assignments.have_different_values_for?(attribute)
        'varies'
      else
        assignments.first.send(attribute)
      end
    end
    private :assignments_common_value_for

    private def same_group_chat_config?
      gchat_assignments_config = assignments.collect(&:group_chat_assignment_config)
      (gchat_assignments_config.collect(&:group_minimum).all_same? &&
        gchat_assignments_config.collect(&:group_maximum).all_same?)
    end

    def varying_due_dates?
      !assignments.collect(&:due_date).all_same?
    end
    private :varying_due_dates?

    def varying_track_group_names?
      !assignments.collect(&:track_group_name).all_same?
    end
    private :varying_track_group_names?

    def varying_categories?
      !assignments.collect(&:category).all_same?
    end
    private :varying_categories?
  end
end
