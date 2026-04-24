require 'data_admin'

class Course < ApplicationRecord
  include Steppable
  include Dangerfield::Publisher
  include EnrollmentEngine::CourseDurationOverlap
  include Etl
  include Enterprise::Scopes

  attr_accessor :copy_created_activities_from_previous_course,
                :copy_shared_activities_from_previous_course,
                :course_library_from,
                :updated_by,
                :validate_categories

  default_scope { where(is_archived: false, is_template: false) }

  after_create :create_library, :if => :program
  after_update :resync_portfolio, if: :saved_change_to_share_to_portfolio?
  after_commit :update_gradebook

  belongs_to :creator,
             class_name: 'User',
             foreign_key: 'creator_guid',
             primary_key: 'guid'
  belongs_to :first_unit, class_name: 'Unit'
  belongs_to :last_unit,  class_name: 'Unit'

  # inverse_of is needed for owner because of non-standard foreign-key/class
  belongs_to :owner,
             class_name: 'Instructor',
             foreign_key: 'owner_id',
             inverse_of: :courses
  belongs_to :program
  belongs_to :school

  has_many :sections, class_name: 'Section'
  has_one :enterprise_section, -> { enterprise }, class_name: 'Section', inverse_of: :course
  has_many :assignments, through: :sections
  # inverse_of is needed for categories because of accepts_nested_attributes
  has_many :categories,
           -> { order(:rank) },
           autosave: true,
           inverse_of: :course,
           dependent: :destroy

  has_one :assignment_filter
  has_many :activity_notes
  has_many :course_library_activities
  has_one :cartridge_course_context_detail, class_name: 'Cartridge::CourseContextDetail',
                                            dependent: :destroy
  has_many :course_standard_sets, dependent: :destroy
  has_many :standard_sets, through: :course_standard_sets

  delegate :gradebook_analytics_enabled?, to: :school

  accepts_nested_attributes_for :categories, allow_destroy: true
  accepts_nested_attributes_for :enterprise_section

  scope :open, -> { where('courses.end_date >= ?', Time.zone.now.to_date) }
  # Scopes named `open` clash with Kernel.open (see https://github.com/rails/rails/issues/2508)
  #   so this alias is meant as a workaround (see Instructor model for more details and example
  #   usage).
  class << self
    alias_method :open_course, :open
  end
  scope :closed, -> { where('courses.end_date < ?', Time.zone.now.to_date) }
  scope :editable, -> { where('courses.end_date >= ?', Time.zone.now.to_date - 1.month) }
  scope :by_program, ->(program) { where(program_id: program.id) }
  scope :by_school, ->(school) { where(school_id: school.id) }
  scope :by_year, ->(year) { where(["courses.start_date LIKE ?", "#{year}%"]) }
  scope :drafts_by_owner, ->(owner) { where(draft: true, owner_id: owner.id) }
  scope :including_templates, -> { unscope(where: :is_template) }
  scope :templates, -> { including_templates.where(is_template: true) }

  serialize :course_package_ids
  serialize :portfolio_activity_types, JSON

  validates_numericality_of :owner_id, :greater_than => 0, :only_integer => true
  validates_numericality_of :program_id, :greater_than => 0, :only_integer => true
  validates_numericality_of :school_id, :greater_than => -1, :only_integer => true, :only => :create
  validates_presence_of :name, :first_unit_id, :last_unit_id

  validate :end_date_must_be_valid_type, :start_date_must_be_valid_type,
           :start_date_must_be_before_assignments, :end_date_must_be_after_assignments, :validate_dependents
  validate :end_date_must_be_in_future, :unless => :allow_past_end_date?  # allow condition is only valid for test scenarios

  validates_date(
    :end_date,
    after: Date.new(2000),
    after_message: 'year must be greater than 2000',
    before: -> { 3.years.from_now },
    before_message: 'must not be more than 3 years from now',
    invalid_date_message: "must be a Date base class",
    if: :end_date_has_no_errors?
  )

  validates_date :start_date, :after => Date.new(2000),
                              :before => :end_date,
                              :before_message => "must come before End date",
                              :after_message => 'year must be greater than 2000',
                              :invalid_date_message => "must be a Date base class",
                              :if => :start_date_has_no_errors?

  validate :first_unit_is_before_last_unit, :units_are_from_the_same_program
  validate :categories_must_be_present, if: :validate_categories, on: :create
  validates :standard_sets, unless: :program_support_standard_sets?, absence: true
  validate :validate_standard_sets, if: :program_support_standard_sets?
  validate :single_enterprise_section

  alias_method :last_lesson, :last_unit
  alias_method :last_chapter, :last_unit

  before_validation :ensure_creator

  EXPIRED_MESSAGE = "Course setup process expired"

  def self.default_values
    {
      draft: true,
      name: 'New course'.freeze,
      start_date: Date.current,
      end_date: Date.current + 14.weeks
    }
  end

  def all_error_messages
    (errors.full_messages + categories.flat_map do |category|
      category.errors.full_messages
    end).uniq
  end

  def activity_xml_filepaths_for_all_attempts
    Attempt.activity_xml_file_paths(sections)
  end

  def response_xml_filepaths_for_all_attempts
    #TODO: we don't store responses in xml anymore. This should be changed to return DB subset
    return []
  end

  def self.open_by_program(program)
    open.by_program(program)
  end

  def self.closed_by_program(program)
    closed.by_program(program)
  end

  def self.editable_by_program(program)
    editable.by_program(program)
  end

  def sections_by_instructor(instructor)
    if accessible_by_admin_for_enterprise?(instructor)
      sections.includes(:course)
    else
      sections.by_instructor(instructor).includes(:course)
    end
  end

  def self.find_guid(id)
    where(id: id).pluck(:guid).first
  end

  def self.by_guid(guid)
    find_by_guid(guid)
  end

  def activities(current_user)
    Activity.where(
      id: ::Services::TocActivityList.all_for_program(
        self.program,
        sections: self.sections,
        current_user:
      )
    )
  end

  def sections_with_assignments
    sections.select do |section|
      section.assignments.count > 0
    end
  end

  def steps
    %w[course content gradebook summary]
  end

  def start_date=(val)
    val = val.to_date if [ActiveSupport::TimeWithZone, Time].include? val.class
    write_attribute(:start_date, val)
  end

  def end_date=(val)
    val = val.to_date if [ActiveSupport::TimeWithZone, Time].include? val.class
    write_attribute(:end_date, val)
  end

  def open?
    !closed?
  end

  def closed?
    (end_date && end_date < Time.now.in_time_zone(time_zone).to_date)
  end

  def editable?
    end_date && end_date >= (Time.now.in_time_zone(time_zone).to_date - 1.month)
  end

  def created_from_enterprise?
    is_enterprise?
  end

  def created_from_template?
    source_template_id.present?
  end

  def time_zone
    if sections.empty?
      if school && school.time_zone
        school.time_zone
      else
        'Eastern Time (US & Canada)'
      end
    else
      sections.first.time_zone || 'Eastern Time (US & Canada)'
    end
  end
  private :time_zone

  private def ensure_creator
    return unless attributes['creator_guid'].nil? && owner&.guid

    self[:creator_guid] = owner.guid
  end

  def owner
    User.unscoped { super }
  end

  def owned_by?(instructor)
    owner == instructor
  end

  def units_covered
    return @units_covered if defined?(@units_covered)
    units = program.units.in_rank_range(first_unit.rank, last_unit.rank)
    @units_covered = program.browsable_units(units)
  end

  def lessons_covered
    units_covered.flat_map(&:lessons).uniq.sort_by do |lesson|
      lesson.name.match(/(\d+)/); [$1.to_i, lesson.rank]
    end
  end

  def weeks_covered
    weeks = []
    start_week = Week.week_containing(start_date)
    end_week = Week.week_containing(end_date)
    start_week.up_to(end_week) {|week| weeks << week}
    weeks
  end

  def week_number(date)
    week_of = Week.week_containing(date.to_date)
    num = weeks_covered.index(week_of)
    num += 1 if num
  end

  def contains_unit?(unit)
    return true if unit.current_events?
    unit.rank >= first_unit.rank && unit.rank <= last_unit.rank
  end

  def <=>(other)
    other.created_at <=> self.created_at
  end

  def self.find_school_courses(schools)
    includes(:program, :school, :sections).where(school_id: schools)
  end

  def self.find_archived(id)
    unscoped.where(id: id, is_archived: true).first
  end

  # TODO: create a named scope 'joinable'
  # so you can say: Course.joinable.by_school(school)
  #             and Course.joinable.by_school(school).by_program(program)
  def self.find_joinable_at_school(school_id, program_id = nil)
    conditions = {:school_id => school_id}
    conditions.merge!({:program_id => program_id}) if program_id

    joinable_conditions = ["courses.is_archived = 0 AND courses.is_demo = 0 AND courses.end_date > ?", Time.zone.today]

    # if no program specified, does not return courses that have only sections that are archived
    # (why only when no program specified ?)
    unless program_id
      joinable_conditions[0] += " AND sections.is_archived = 0"
    end

    where(conditions).joins(:sections)
      .includes(:program, :sections)
      .where(joinable_conditions)
      .group('courses.id')
  end

  def validate_total_category_weights
    return true if categories.none?

    errors.add(:base, "Category weights must add up to 100%, currently #{(total_category_weight)}%") if total_category_weight != 100
    errors.none?
  end

  def total_category_weight
    @total_category_weight ||= categories.inject(0) do |sum, category|
      sum + (category.marked_for_destruction? ? 0 : category.weighting_percent)
    end
  end

  def categories_with_assessment_counts
    # Retrieves categories for course and adds assessment count field to them.
    # An assignment's assessment-ness is determined by a boolean value on
    # an assignment's associated activity's concept.
    Category.with_assessment_count(self)
  end

  def course_events_in_range?
    course_events.each do |event|
      if event.date < start_date || event.date > end_date
        errors.add(:base, "Holidays must fall within course dates")
      end
    end
  end

  def has_enrollments?
    !!sections.detect{|section| section.enrollments.exists? }
  end

  def assignments?
    !!categories.detect{|category| category.assignments.exists? }
  end

  def prospective_additional_instructors
    school.active_instructors_with_program_access(program)
  end

  def end_date_must_be_in_future
    return false unless end_date && end_date.is_a?(Date)
    if end_date < Time.now.in_time_zone(time_zone).to_date
      errors.add(:base, "End date should not be in the past.")
      return false
    end
    return true
  end

  def draft_expired?
    errors.full_messages.include?(EXPIRED_MESSAGE)
  end

  def sections_count
    sections.count
  end

  def archived?
    self.is_archived
  end

  def archive
    if sections.count > 0
      sections.each  do |section|
        if section.students.count > 0
          errors.add(
            :base,
            "Course <b>#{name}</b> has section(s) with student(s). You " \
            'must delete each section individually in its Edit Section page.'
          )
          return self
        end
        if section.assignments.count > 0
          errors.add(
            :base,
            "Course <b>#{name}</b> has section(s) with assignment(s). You " \
            'must delete each section individually in its Edit Section page.'
          )
          return self
        end
      end
    end

    sections.each(&:archive)
    enterprise_section.archive if is_enterprise?

    categories.each do |category|
      category.update(is_archived: true)
    end

    update(is_archived: true, allow_past_end_date: true)
  end

  def section_class_days_vary?
    sections.collect(&:class_days).uniq.count > 1
  end

  def covers_all_program_units?
    units_covered.collect(&:id).sort == program.units.collect(&:id).sort
  end

  # for testing, permits old course creation
  def allow_past_end_date=(val)
    @allow_past_end_date = val
  end

  def possible_video_languages
    foreign_label = program.language_name
    languages_options = [[foreign_label, 'foreign'], ['None', 'none']]
    # Only add Foreign and English if the program is not an English program.
    if program.language_code != 'en'
      languages_options.insert(1, ["#{foreign_label} and English", 'foreign_and_english'])
    end
    languages_options
  end

  def validate_dependents
    if validate_total_category_weights
      categories.each do |category|
        if category.marked_for_destruction? && !category.destroyable?
          errors.add(:base, category.errors.full_messages.uniq.join(' '))
        end
      end
      errors.none?
    end
  end
  private :validate_dependents

  def program_share_to_portfolio?
    program&.share_to_portfolio?
  end

  def course_share_to_portfolio?
    program_share_to_portfolio? && share_to_portfolio?
  end

  def activity_share_to_portfolio?(activity_type)
    course_share_to_portfolio? &&
      !!portfolio_activity_types&.dig(activity_type)
  end

  def concurrent_enrollment_enabled_for_program?
    program&.enable_concurrent_enrollment?
  end

  def chat_disabled?
    chat_level == 'disabled'
  end

  def chat_enabled?
    !chat_disabled?
  end

  def live_chat_enabled?
    chat_level == 'partner_chat_and_live_chat'
  end

  def partner_chat_enabled?
    chat_level == 'partner_chat' || chat_level == 'partner_chat_and_live_chat'
  end

  def create_library
    if course_library_from
      if copy_created_activities_from_previous_course
        CourseActivitiesCopier.new(course_library_from, id).copy
      elsif copy_shared_activities_from_previous_course
        CourseActivitiesCopier.new(course_library_from, id, shared_only: true).copy
      end
    end
  end

  def hide_from_instructor_dash(hide_flag)
    SectionInstructor
      .where(section: sections, user_id: owner_id, role: 'Instructor')
      .update_all(hide_from_instructor_dashboard: hide_flag)
  end

  def resync_portfolio
    return unless share_to_portfolio

    Portfolio::BulkGroupsResyncWorker.perform_async(id)
  end

  def first_unit_is_before_last_unit
    if first_unit && last_unit && program
      unit_label = "unit"
      unit_label = program.unit_label.downcase unless program.unit_label.blank?
      unit_field_name = "last_#{unit_label}"
      errors.add(unit_field_name, "must come after First #{unit_label}") if (last_unit.rank < first_unit.rank)
    end
  end
  private :first_unit_is_before_last_unit

  def units_are_from_the_same_program
    if first_unit && last_unit && program
      unit_label = "unit"
      unit_label = program.unit_label.downcase unless program.unit_label.blank?
      unit_field_name = "last_#{unit_label}"
      errors.add(unit_field_name.to_sym,"must be in the same program as First #{unit_label}") if (last_unit.program_id != first_unit.program_id)
    end
  end
  private :units_are_from_the_same_program

  private def categories_must_be_present
    return if categories.is_a?(ActiveRecord::Associations::CollectionProxy) &&
              categories.present?

    errors.add(:course, 'must have at least one category.')
  end

  def course_date_range
    (start_date..end_date)
  end
  private :course_date_range

  def start_date_has_no_errors?
    errors[:start_date].blank?
  end
  private :start_date_has_no_errors?

  def end_date_has_no_errors?
    errors[:end_date].blank?
  end
  private :end_date_has_no_errors?

  def start_date_must_be_valid_type
    begin
      Date.parse(start_date.to_s)
    rescue
      errors.add(:start_date, 'is required.')
    end
  end
  private :start_date_must_be_valid_type

  def start_date_must_be_before_assignments
    return if assignments.empty?

    first_due_date = assignments.minimum(:due_date).to_date
    if start_date > first_due_date
      errors.add(:start_date, "must be before the first assignment! (#{first_due_date.to_formatted_s(:slash_month_day_long_year)})")
    end
  end
  private :start_date_must_be_before_assignments

  def end_date_must_be_valid_type
    begin
      Date.parse(end_date.to_s)
    rescue
      errors.add(:end_date, 'is required.')
    end
  end
  private :end_date_must_be_valid_type

  def end_date_must_be_after_assignments
    return if assignments.empty? || !end_date_has_no_errors?

    last_due_date = assignments.maximum(:due_date).to_date
    if end_date < last_due_date
      errors.add(:end_date, "must be after the last assignment! (#{last_due_date.to_formatted_s(:slash_month_day_long_year)})")
    end
  end
  private :end_date_must_be_after_assignments

  private def allow_past_end_date?
    @allow_past_end_date
  end

  # overrides is_deleted in the Etl module
  def is_deleted?
    archived? || super
  end

  # need "Course" sent to gradebook as model name,
  # not any subclass (like DemoCourse)
  def gradebook_class_name
    'Course'
  end

  # covers cases where we trigger the same behavior for
  # either RA courses or LTI-Adv rostered courses
  # e.g. course editing...
  def autorostering_linked?
    sections.any?(&:autorostering_linked?)
  end

  # TBD whether or not we will need to change functionality for
  # only LTI rostered courses; but adding this for completeness
  def lti_roster_linked?
    sections.any?(&:lti_roster_linked?)
  end

  def one_roster_linked?
    sections.any?(&:one_roster_linked?)
  end

  def has_one_roster_academic_session?
    sections.any? do |section|
      section.one_roster_linked_section&.academic_session.present?
    end
  end

  def start_end_date(format = '%-m/%-d/%Y')
    #  As an example: 4th of January will be formatted as 1/4/2020 by default
    [start_date, end_date].map { |d| d.strftime(format) }.join(' - ')
  end

  def has_individual_assignments?
    assignments.where(individually_assignable: true).exists?
  end

  def any_due_dates_reached?
    assignments.empty? ? false : assignments.minimum(:due_date).to_date <= Time.zone.now.to_date
  end

  private def program_support_standard_sets?
    program&.supported_standard_sets&.present?
  end

  # Validates that if a list of standard sets is present, all the standard sets
  # are supported by the associated program.
  private def validate_standard_sets
    if standard_set_ids.present?
      result = standard_set_ids - program.supported_standard_set_ids
      if result.present?
        errors.add(:standard_sets, 'must be supported by the program')
      end
    end
  end

  private def single_enterprise_section
    return unless is_enterprise?

    enterprise_sections = sections.select(&:is_enterprise) + [enterprise_section].compact

    if enterprise_sections.size > 1
      errors.add(:sections, 'can only have one enterprise section')
    end
  end

  private def accessible_by_admin_for_enterprise?(instructor)
    is_enterprise? && !owned_by?(instructor) && instructor.institution_admin?
  end
end
