class Assignment < ApplicationRecord
  include Etl

  # need to include and extend so that the methods are available
  # at the class level as well as the instance level
  include ::TimeHandler
  extend ::TimeHandler
  extend IndividualAssignmentQueryable
  include Etl

  belongs_to :section, -> { including_enterprise }
  belongs_to :category
  belongs_to :assignable, :polymorphic => true
  has_one :course, :through => :section
  # inverse_of for assigned_assessment_detail is needed because of
  # acceptes_nested_attributes.
  has_one :assigned_assessment_detail, inverse_of: :assignment
  has_one :program, :through => :course
  has_one :group_chat_assignment_config
  belongs_to :track_group, optional: true

  attr_accessor :vol_program

  after_commit :update_gradebook
  after_commit :destroy_group_chat_config, on: :destroy, if: :group_chat?

  accepts_nested_attributes_for :assigned_assessment_detail, :allow_destroy => true, :reject_if => :reject_details

  validates_datetime :due_date, :invalid_datetime_message => 'must be a valid date.',
                                :allow_nil => true,
                                :allow_blank => true
  validate :due_date_not_null
  validates_presence_of :category_id, :message => 'is required.'
  validates_presence_of :track_group_id, :message => 'is required.', :if => :requires_track_group?
  validate :within_course_range

  # For some reason the message desired is not shown in the validates_datetime call when show_at is nill or blank
  validates_datetime :show_at, :before => :due_date_time,
                               :before_message => "The #singular_label# must be available before it is due.",
                               :invalid_datetime_message => 'You must specify a valid release date.',
                               :if => :release_on_specific_date?,
                               :allow_nil => true,
                               :allow_blank => true

  validates_datetime :grades_available_at, :after => :show_at,
                                           :on_or_after => :due_date_time,
                                           :on_or_after_message => 'Results for this #singular_label# can only be made available after it is due.',
                                           :after_message => "Results for this #singular_label# can only be made available after it is released.",
                                           :invalid_datetime_message => 'You must specify a valid result availability date.',
                                           :if => :grade_available_on_specific_date?,
                                           :allow_nil => true,
                                           :allow_blank => true

  validate :release_date_not_null, :if => :release_on_specific_date?
  validate :grade_availability_date_not_null, :if => :grade_available_on_specific_date?

  scope :due_on, ->(date) { where(due_date: date) }
  scope :due_on_week, lambda { |date| where("due_date >= :start_date AND due_date <= :end_date",{ start_date: date, end_date: date + 6 }) }
  scope :not_external, -> { where(assignable_type: 'Activity') }

  scope :by_section, ->(*sections) { where(section_id: sections.flatten(1)) } do
    def have_different_values_for?(attribute_name)
      collect { |element| element[attribute_name] }.vary?
    end
  end
  scope :by_assignable_id, ->(*activities) { where(assignable_id: activities) }

  scope :by_activities, lambda { |*activities|
    where(assignments: { assignable_type: 'Activity', assignable_id: activities.map(&:id) })
  }

  ACTIVITIES_JOIN = 'INNER JOIN activities ' \
                    'ON activities.id = assignments.assignable_id'.freeze
  scope :non_practice_uncompleted, lambda { |user, section|
    joins(ACTIVITIES_JOIN).joins(
      "LEFT OUTER JOIN attempts
        ON attempts.activity_id = activities.id
        AND attempts.user_id = #{user.id}
        AND attempts.section_id = assignments.section_id
        AND attempts.status_code = 2"
    ).where(attempts: { id: nil }, section_id: section)
  }

  after_validation :post_process_availability_error_message

  scope :released, lambda {
    where(
      [
        'assignments.show_at IS NOT NULL AND assignments.show_at <= ?',
        Time.zone.now
      ]
    )
  }

  scope :by_category, ->(category) { where(category_id: category) }

  scope :in_unarchived_section, -> { joins(:section).where(sections: { is_archived: false }) }
  scope :by_concept, lambda { |*concepts|
    not_external.joins(ACTIVITIES_JOIN).where(
      activities: { concept_id: concepts.map(&:id) }
    )
  }
  scope :by_type, ->(_) { not_external.joins(ACTIVITIES_JOIN) }

  scope :by_due_date, lambda { |date|  where(due_date: date) }
  scope :current, lambda { where(current: true) }

  scope :incomplete_by_user, lambda { |user|
    not_external.joins(
      'LEFT OUTER JOIN attempts ON attempts.activity_id = assignments.assignable_id ' \
      " AND attempts.section_id = assignments.section_id AND attempts.user_id = #{user.id} " \
      " AND attempts.status_code = #{AttemptStatus::CODE_COMPLETED}"
    ).where(attempts: { id: nil })
  }

  delegate :name, to: :section, prefix: true
  delegate :name, to: :category, prefix: true
  delegate :assessment?, to: :assignable, allow_nil: true
  delegate :lesson_label, to: :assignable, allow_nil: true, prefix: true
  delegate :name, to: :track_group, prefix: true, allow_nil: true

  def reject_details(attrs)
    attrs.empty? || (attrs["time_limit"].to_i == 0 && attrs["password"].blank? && attrs["number_of_attempts"].to_i == 1)
  end
  private :reject_details

  def self.human_attribute_name(attribute_key_name, options = {})
    # Don't use the default attribute name prefixes in the validation messages
    # because these attributes have custom messages that better describe the
    # UI element that must be corrected. e.g.
    #  "Grades for this #singular_label# can only be made available after it is released."
    #  "Grade availability date is required."
    # For assigned_assessment_detail.password, the prefix is overridden so it
    # doesn't display "Assigned Assessment Detail: Password must be..." since
    # assigned_assessment_details is a child table storing additional
    # assignmen attrs and isn't referenced in the UI at all.
    case attribute_key_name.to_sym
    when :show_at, :grades_available_at,
      :'assigned_assessment_detail.time_limit',
      :'assigned_assessment_detail.password' then ''
    else super
    end
  end

  def self.by_section_and_activity(section, *activities)
    by_section(section).by_activities(*activities)
  end

  def self.by_activities_and_sections(activities, sections)
    by_activities(*activities).by_section(*sections)
  end

  def self.by_activity_list_completed_and_released(activities, user, section)
    submitted_activities = Attempt.where(
      activity_id: activities,
      section_id: section,
      status_code: AttemptStatus::CODE_COMPLETED,
      user_id: user
    ).pluck(:activity_id)

    apply_individual_assignment_filter(
      not_external.where(assignable_id: submitted_activities).released,
      user.id
    )
  end

  def self.incomplete_released_non_practice_by_activity_list(assessments, user, section)
    apply_individual_assignment_filter(
      by_activities(*assessments).non_practice_uncompleted(user, section).released,
      user.id
    )
  end

  def self.unique_due_dates_by_section_and_category(section_ids, category_id)
    if category_id.nil? || category_id == 0
      by_section(*section_ids).distinct.order(:due_date)
    else
      by_section(*section_ids).by_category(category_id).distinct.order(:due_date)
    end
  end

  # An assessment is untimed if the time_limit is nil or 0
  def timed?(student)
    time_limit_for_student(student).positive?
  end

  # use this method to obtain the time_limit when displaying assessment details
  # to the student and to set the activity timer
  def time_limit_for_student(student)
    AssessmentStudentTimeLimit.student_time_limit(
      section_id,
      assignable_id,
      student
    ).try(:time_limit) || time_limit
  end

  # this method should be called only when the assignment's time_limit is needed
  # such as when displaying that information for the instructor
  def time_limit
    (assigned_assessment_detail && assigned_assessment_detail.time_limit) || 0
  end

  def self.next_rank(section, due_date, activity)
    NextRankFinder.new(section, due_date, activity).next_rank
  end

  def self.by_section_and_unit(section, unit)
    where(:section_id => section, :assignable_type => 'Activity')
      .joins('INNER JOIN activities ON activities.id = assignments.assignable_id')
      .joins('INNER JOIN lessons ON lessons.id = activities.lesson_id')
      .where('lessons.unit_id' => unit)
  end

  def self.update_assignment(old_assignment, new_params = {})
    params = old_assignment.attributes.except('id', 'updated_at')
    old_time_limit = old_assignment.time_limit if old_assignment.assessment?

    Assignment.transaction do
      old_assignment.destroy
      new_assignment = create!(params.merge(new_params))

      new_assignment.check_student_time_limits(old_time_limit) if new_assignment && old_time_limit

      update_assignment_set_activity(old_assignment, new_assignment)

      new_assignment
    end
  end

  def self.update_assignment_set_activity(old_assignment, new_assignment)
    # if the due date does not change it means the assignment_set_activity
    # is already created associated to the correct assignment set and we
    # dont need to re-create the record because that would make us loose the rank.
    return if old_assignment&.due_date == new_assignment&.due_date

    old_assignment&.destroy_assignment_set_activity
    new_assignment&.create_assignment_set_activity
  end

  # Check if the assignment due date has been released to the student
  # Instructors can set the number of days to show the assignment due date
  #   as part of the section set-up
  # The assignments are always available for the students to see, but the
  #   due dates are hidden
  def due_date_released?
    release_days = section.days_to_show_assignment_due_date
    return true if release_days.nil?
    (due_date_time - Time.now.in_time_zone(section.time_zone)).floor / 1.day <= release_days
  end

  # if the assessment time_limit has been removed, delete any associated student time limits
  def check_student_time_limits(old_time_limit)
    if old_time_limit.positive? && time_limit.zero?  # time_limit was removed
      AssessmentStudentTimeLimit.delete_time_limits(section_id, assignable_id)
    end
  end

  def self.assessments_for_section(section)
    by_section(*section).where('show_assessment is not null')
  end

  def grade_availability
    if self[:grade_availability].present?
      self[:grade_availability].to_sym
    else
      :on_grading
    end
  end

  def update_availability(type)
    case type
    when 'assessment_release' then set_date_value :show_at
    when 'grade_release'      then set_date_value :grades_available_at
    end
  end

  def due_date_in_future?
    utc_now = Time.now.utc
    utc_due_date_time = due_date_time.utc

    if utc_due_date_time.day_minute > utc_now.day_minute
      utc_due_date_time.to_date >= utc_now.to_date
    else
      utc_due_date_time.to_date > utc_now.to_date
    end
  end

  # We're using section_course because accessing the course association in
  # this one place triggers a timestamp update on the course model.
  private def within_course_range
    section_course = section&.course
    return if section_course.blank?
    return if errors[:due_date].present?

    start_date = section_course.start_date
    start_date_formatted = start_date.to_date.strftime('%m/%d/%Y')

    end_date = section_course.end_date
    end_date_formatted = end_date.to_date.strftime('%m/%d/%Y')

    unless due_date >= start_date
      due_date_error("must be after course start date, which is #{start_date_formatted}")
    end

    return if due_date <= end_date

    due_date_error("must be before course end date, which is #{end_date_formatted}")
  end

  private def due_date_error(message)
    errors.add(:due_date, message)
  end

  def in_week(week)
    (due_date >= week && due_date <= (week + 6))
  end

  def late?(submitted_at)
    submitted_at.present? && (submitted_at > due_date_time)
  end

  def due_time_zone
    Time.use_zone(section.time_zone) do
      due_date_time.zone
    end
  end

  def due_date_time
    Time.use_zone(section.time_zone) do
      Time.zone.local(due_date.year, due_date.month, due_date.day,
                      due_time.hour, due_time.min)
    end
  end

  def points_possible
     assignable.points_possible
  end

  def max_attempts
    category.max_attempts
  end

  def completed?
    false
  end

  def credit_only?
    @credit_only = category.credit_only? if @credit_only.nil?
    @credit_only
  end

  def assessment_grade_available?
    return false if grade_availability.nil?
    case grade_availability
    when :never            then false
    when :on_release,
         :on_specific_date then grades_available_at_in_past?
    when :on_due_date      then due_date_in_past?
    when :on_grading       then all_students_graded?
    else false
    end
  end

  def score_actions(student_ids)
    GradebookEngine::GradebookAPI.find_submitted(activity_id: assignable_id,
                                                 section_id: section_id,
                                                 user_id: student_ids)
  end

  def self.create_assignment_calendar(section, user, from, to) #tom
    first_date = Date.new(from.year, from.month, 1).to_s
    last_date = Date.new(to.year, to.month, -1).to_s
    conditions = ["section_id = ? AND due_date >= ? AND due_date <= ?", section, first_date, last_date]
    assignments = where(conditions)
    calendar = AssignmentCalendar.new(from, to)
    assignments.each {|assignment| calendar << assignment}
    calendar
  end

  # Return all assignments due before today.
  def self.past_assignments(section, date = nil)
    date ||= date_for_zone(section.time_zone)
    includes(:assignable).where(['section_id = ? AND due_date < ?', section, date])
  end

  # Return all assignments due today or later.
  def self.future_assignments(section, date = nil)
    date ||= date_for_zone(section.time_zone)
    includes(:assignable).where(['section_id = ? AND due_date >= ?', section, date])
  end

  def self.activity_assignments(sections, activities, category_id = nil)
    scope = Assignment.by_section(*sections)
    scope = scope.by_category(category_id) if category_id
    scope.by_activities(*activities)
  end

  def due_in_future?
    due_date > date_for_zone(section.time_zone)
  end

  # TODO: make this a scope
  def self.find_by_sections_and_category(sections, category_id)
    where(category_id: category_id, section_id: sections).order(:due_date)
  end

  def self.find_with_course_category(section, activity)
    return unless section
    assignment = Assignment.includes(:category).where(
      section_id: section.id,
      assignable_id: activity.id,
      assignable_type: activity.class.to_s
    ).first
    return unless assignment && assignment.category
    assignment
  end

  def self.filtered_assignments(sections, filter)
    filter_1 = set_filter(filter[:filter_1], filter[:filter_1_value], sections)
    filter_2 = set_filter(filter[:filter_2], filter[:filter_2_value], sections)

    get_everything(sections, [filter_1, filter_2], ignore_current = true)
  end

  def self.set_filter(filter_key, filter_value, sections)
    case(filter_key)
    when 'lesson'
      lesson_filter_condition(filter_value)
    when 'section'
      strand_filter_condition(sections.first.strand_ids_by_name(filter_value, true))
    when 'category'
      category_filter_condition(filter_value)
    when 'week'
      (year, month, day) = filter_value.split('-')
      start_date = Date.new(year.to_i, month.to_i, day.to_i)
      end_date = start_date + 6.days
      week_filter_condition(start_date.to_formatted_s(:db), end_date.to_formatted_s(:db))
    when 'day'
      (month, day, year) = filter_value.split('/')
      filter_date = Date.new(year.to_i, month.to_i, day.to_i)
      day_filter_condition(filter_date.to_formatted_s(:db))
    end
  end

  def self.get_everything(sections, filter_conditions = [], ignore_current = false)
    internal_activity_join = "inner join activities on activities.id = assignments.assignable_id " +
                             "and assignments.assignable_type = 'Activity'" +
                             "left outer join lessons on activities.lesson_id = lessons.id "

    assignments_condition = { section_id: sections.to_a }
    assignments_condition[:current] = true unless ignore_current

    base_assignment_scope = where(assignments_condition)

    internal_activity_scope = base_assignment_scope.joins(internal_activity_join)
    # this here is a hack that will get us what we need for now, but
    # this whole damn method needs a total re-write...starting with the
    # name... get_everything!
    filter_conditions.each do |filter_condition|
      internal_activity_scope = internal_activity_scope.where(filter_condition)
    end

    internal_activity_scope
  end

  def self.week_filter_condition(start_date, end_date)
    ["due_date between ? and ?", start_date, end_date]
  end

  def self.day_filter_condition(due_date)
    {:due_date => due_date}
  end

  def self.category_filter_condition(category_value)
    {:assignments => {:category_id => category_value}}
  end

  def self.lesson_filter_condition(lesson_value)
    {:activities => {:lesson_id => lesson_value}}
  end

  def self.strand_filter_condition(strand_value)
    {:activities => {:toc_location => strand_value}}
  end

  def create_assignment_set_activity
    assignment_set = AssignmentSet.find_by(due_date: due_date, section_id: section_id)
    return unless assignment_set

    rank = (assignment_set.activities.maximum(:assignment_set_rank) || 0) + 1
    assignment_set.activities.create!(activity_id: assignable_id, assignment_set_rank: rank)
  end

  def destroy_assignment_set_activity
    assignment_set = AssignmentSet.find_by(due_date: due_date, section_id: section_id)
    return unless assignment_set

    assignment_set.activities.where(activity_id: assignable_id).destroy_all
  end

  def shown?
    show_at && (show_at < Time.zone.now)
  end

  def sections_in_course_count
    all_sections_in_course.count
  end

  def due_time
    custom_due_time || section.due_time
  end

  def all_sections_in_course
    course.sections
  end

  def scoring_ruleset
    # verify category exists first?
    category.current_scoring_ruleset
  end

  def disable_enhanced_feedback?
    # verify category exist first?
    category.enhanced_feedback_disabled?
  end

  def has_password?
    assigned_assessment_detail && assigned_assessment_detail.password && assigned_assessment_detail.password.length > 0
  end

  def time_limit
    (assigned_assessment_detail && assigned_assessment_detail.time_limit) || 0
  end

  def gb_deletion_opts
    { :model_name => self.gradebook_class_name, :id => self.id, :section_id => self.section_id, :assignable_id => self.assignable_id, :action => 'delete' }
  end

  # overrides method in Etl module;
  # Assignments must update the Gradebook directly
  # instead of using Sidekiq to maintain the order by
  # which an Assignment is deleted and then re-added when
  # it is re-assigned.
  def notify_update
    opts = { :model_name => self.gradebook_class_name, :id => self.id, :action => 'add_update' }
    invoke_gb_updater(opts)
  end

  # overrides method in Etl module;
  # Assignments call GradebookApi directly
  def notify_deletion
    invoke_gb_updater(gb_deletion_opts)
  end

  private def invoke_gb_updater(opts)
    return if Rails.env.test? && !Rails.application.config.update_test_gradebook

    "Gb#{self.gradebook_class_name}Migrator".classify.constantize.new(opts).update_object
  end

  ###################################################
  # end code specific to updating GB from M3

  def randomize_per_student?
    randomize_per_student
  end

  def has_multiple_due_dates?
    # Bail early if not individually assignable: no need to try to find individual assignments.
    return false unless individually_assignable

    individual_assignments = IndividualAssignment.where(
      section: section,
      activity_id: assignable_id
    )

    return false if individual_assignments.count.zero?

    return true if individual_assignments.any? do |ia|
      ia.effective_due_date != due_date
    end

    # If we get to this point,
    # all individual assignments use the default due date
    # _or_ have a custom due date equal to the default.
    false
  end

  private

  def set_date_value(field)
    self[field] = self[field].present? ? nil : date_for_zone(section.time_zone)
  end

  def all_students_graded?
    student_ids = section.current_student_ids
    @scores ||= score_actions(student_ids)
    all_scores_equal_roster_size?(@scores, student_ids) ||
      past_due_and_graded_scores_equal_submitted_scores?(@scores)
  end
  private :all_students_graded?

  def all_scores_equal_roster_size?(scores, student_ids)
    non_pending_score_actions(scores).size == student_ids.size
  end
  private :all_scores_equal_roster_size?

  def past_due_and_graded_scores_equal_submitted_scores?(scores)
    due_date_in_past? && non_pending_score_actions(scores).size == submitted_score_actions(scores).size
  end
  private :past_due_and_graded_scores_equal_submitted_scores?

  private def non_pending_score_actions(scores)
    scores.reject(&:pending?)
  end

  private def submitted_score_actions(scores)
    scores.select { |s| s.submitted_at.present? }
  end

  def grades_available_at_in_past?
    grades_available_at.present? && grades_available_at < Time.zone.now
  end
  private :grades_available_at_in_past?

  def due_date_in_past?
    !due_date_in_future?
  end
  private :due_date_in_past?

  def self.assignable_conditions(activities)
    [
      "assignable_type = 'Activity' AND assignable_id IN (?)",
      activities
    ]
  end

  def release_on_specific_date?
    show_assessment == 'a specific date and time'
  end

  [:on_specific_date, :on_due_date, :on_release].each do |method|
    define_method("grade_available_#{method.to_s}?") do
      grade_availability == method
    end
  end

  def release_date_not_null
    return if show_at.present? || errors[:show_at].present?

    errors.add(:show_at, 'Release date is required.')
  end

  def grade_availability_date_not_null
    return if grades_available_at.present? || errors[:grades_available_at].present?

    errors.add(:grades_available_at, 'Grade availability date is required.')
  end

  def due_date_not_null
    return if due_date.present? || errors[:due_date].present?

    errors.add(:due_date, 'is required.')
  end

  def post_process_availability_error_message
    return if self.assignable.nil? || self.assignable_type != 'Activity' || ( self.errors[:show_at].empty? && self.errors[:grades_available_at].empty? )
    attributes_messages = {}
    set_singular_label = false
    self.errors.each do |error|
      attribute = error.attribute.to_sym

      set_singular_label = true if error.message =~ /#singular_label#/
      attributes_messages[attribute] = Array.new unless attributes_messages[attribute]
      attributes_messages[attribute] << error.message.gsub( '#singular_label#', (self.assignable.strand_singular_label || 'assessment') )
    end
    if set_singular_label
      self.errors.clear
      attributes_messages.each do |attribute, messages|
        messages.each{ |message| self.errors.add(attribute, message) }
      end
    end
  end

  def requires_track_group?
    vol_program && assignable_type == 'Activity'
  end
  private :requires_track_group?

  private def destroy_group_chat_config
    gchat_assignment_config = GroupChatAssignmentConfig.find_by(assignment_id: id)
    gchat_assignment_config.destroy unless gchat_assignment_config.nil?
  end

  private def group_chat?
    assignable.activity_type == 'group_chat' unless assignable_type == 'ExternalActivity'
  end

  class NextRankFinder
    include ScorableSorter

    attr_reader :section, :due_date, :activity

    def initialize(section, due_date, activity)
      @section = section
      @due_date = Date.parse(due_date)
      @activity = activity
    end

    # Gets the next suitable rank when assigining internal activities
    # Bases rank calculation on the ToC concept rank of the activity being assigned within the section and a given due date
    # Returns the assignment rank of the next ranked assigned activity when the given activity's rank isn't the highest concept rank
    # Returns the current max rank + 1 when activity's toc rank is higher than the most ranked assigned activity
    # Returns 1 when there are no other assignments found for the section and due date
    # Assignment rank ties allow assignments to get ordered by their activity's concept rank.
    def next_rank
      if assignments_on_this_due_date.any?
        if (next_assignment = sorted_assignments[new_assignment_index + 1])
          next_assignment.rank
        else
          previous_assignment = sorted_assignments[new_assignment_index - 1]
          previous_assignment.rank + 1
        end
      else
        1
      end
    end

    def new_assignment_index
      sorted_assignments.index(temp_assignment)
    end
    private :new_assignment_index

    def sorted_assignments
      @sorted_assignments ||= sort_by_location([temp_assignment] + assignments_on_this_due_date)
    end
    private :sorted_assignments

    def temp_assignment
      @temp_assignment ||= Assignment.new(due_date: due_date, assignable: activity)
    end
    private :temp_assignment

    def assignments_on_this_due_date
      @assignments_on_this_due_date ||= Assignment.by_section(section)
                                                  .by_type(Activity)
                                                  .where(due_date: due_date)
                                                  .includes(:assignable)
    end
    private :assignments_on_this_due_date
  end
end
