class Section < ApplicationRecord
  include StrandsByName
  include Etl

  alias_attribute :archived, :is_archived # we setup an alias to this attribute
  # since it is required for the callback defined in SectionInstructorArchiver
  # need to include and extend so that the methods are available
  # at the class level as well as the instance level
  include ::TimeHandler
  include SectionInstructorArchiver
  include Dangerfield::Publisher
  include Enterprise::Scopes
  extend ::TimeHandler

  dangerfield_publish_if :publish_changes?
  after_commit :update_gradebook, if: :non_zero?

  default_scope { where(is_archived: false).merge(non_enterprise) }

  belongs_to :course, -> { including_templates }
  belongs_to :instructor, class_name: 'User', foreign_key: 'instructor_id'
  has_many :enrollments do
    def archive
      each do |enrollment|
        enrollment.archive!
      end
    end
  end

  has_many :categories, through: :course
  has_many :students, through: :enrollments, source: :user, class_name: 'Student'
  has_many :current_enrollments, -> { where(state: %w[enrolled marked_complete]) },
           class_name: 'Enrollment'
  has_many :current_active_enrollments, -> { where(state: %w[enrolled]) },
           class_name: 'Enrollment'
  has_many :current_students_base,
           class_name: 'Student',
           source: :user,
           through: :current_enrollments
  has_many :current_active_students_base,
           class_name: 'Student',
           source: :user,
           through: :current_active_enrollments

  # inverse_of for section_instructors is needed because of
  # accepts_nested_attributes.
  has_many :section_instructors,
           -> { where(is_archived: false) },
           autosave: true,
           inverse_of: :section do
    def archive
      # update_all will not trigger dangerfield synchronization, but
      # section_instructors will be archived in UA by after_save hook
      # (see SectionInstructorArchiver)
      update_all(is_archived: true)
    end
  end

  has_many :instructors,
           class_name: 'Instructor',
           source: :instructor,
           through: :section_instructors

  has_many :notifications
  has_many :forums

  has_one :program, -> { where('courses.is_archived = 0') }, through: :course
  has_one :school, -> { where('courses.is_archived = 0') }, through: :course
  has_one :one_roster_linked_section, class_name: 'OneRoster::LinkedSection',
                                      autosave: true, dependent: :destroy
  has_one :cartridge_course_context_detail, class_name: 'Cartridge::CourseContextDetail',
                                            dependent: :destroy

  has_many :assignments do
    def ranked
      order(:rank)
    end
  end
  has_many :attempts
  has_one :lti_context_link, class_name: 'Lti::ContextLink'

  has_many :student_section_configs, dependent: :destroy

  belongs_to :source_template,
             class_name: 'Section',
             foreign_key: 'source_template_id',
             optional: true

  has_many :assignment_sets

  scope :by_instructor, ->(instructor) { joins(:section_instructors).where(section_instructors: { user_id: instructor }) }
  scope :open, -> { joins(:course).where(['courses.end_date >= ? AND courses.is_demo = ? AND courses.is_archived = ?', date_for_zone(), false, false]) }
  scope :by_program, ->(program_id) { joins(:course).where(courses: { program_id: program_id }) }
  scope :by_course, ->(course) { where(course_id: course) }

  validates_presence_of :name
  validates :time_zone, inclusion: {
    in: ActiveSupport::TimeZone.all.map(&:name).concat(
      ActiveSupport::TimeZone.us_zones.map(&:name)
    ),
    message: 'must be a valid time zone.'
  }, allow_nil: true
  validates :class_days, presence: true, if: :is_enterprise?
  validate :enterprise_section_consistency
  validate :single_enterprise_section

  # TODO: change this validation after show/hide in place for all instructors on team
  validate :owner_name_not_hidden_without_additional_instructors

  before_save :set_instructor_team_ids, prepend: true
  before_create :set_shared_false_if_template

  include Steppable

  delegate :show_estimated_times?,
           :allows_review_requests?,
           :allows_help_requests?,
           :name,
           :start_date,
           :end_date, to: :course, prefix: true, allow_nil: true
  delegate :lessons_covered, :school_id, :units_covered, to: :course
  delegate :is_template?, to: :course
  accepts_nested_attributes_for :section_instructors, allow_destroy: true, reject_if: proc { |attributes| attributes[:role].blank? }
  accepts_nested_attributes_for :one_roster_linked_section, allow_destroy: true
  accepts_nested_attributes_for :cartridge_course_context_detail, allow_destroy: true

  def self.section_zero
    section = new
    section.id = 0
    section
  end

  def self.find_guid(id)
    where(id: id).pluck(:guid).first
  end

  def section_zero?
    id == 0
  end

  def assignment_by_activity(activity)
    assignments.by_activities(activity).first
  end

  def ==(other)
    # even if we have different instances of a section_zero
    # we want those instances of section zero to be considered equal
    (self.zero? && other.zero?) || super
  end

  def sample_student
    @sample_student ||= current_students_base.is_fake.first
  end

  def non_zero?
    !(zero?)
  end

  def zero?
    (id == 0)
  end

  private def publish_changes?
    m3_only_attributes = %w[current_upto updated_at]
    (changed - m3_only_attributes).present?
  end

  def steps
    %w[section_information class_days]
  end

  def current_students
    current_students_base
  end

  def current_student_ids
    current_students_base.collect(&:id)
  end

  def weeks_covered
    return [] unless course
    course.weeks_covered
  end

  def maestro3?
    if program
      program.maestro3?
    else
      false
    end
  end

  def open?
    !closed?
  end

  def closed?
    return true if course && course.closed?
    false
  end

  def course_name
    zero? ? 'No course' : course.name
  end

  def section_instructors_including_archived
    # for generating the enterprise admin metrics csv export,
    # the section instructors need to be in order by role
    SectionInstructor.unscoped.where(section_id: id).order(:role)
  end

  def instructor_last_names
    instructors.map(&:last_name)
  end

  def owner_last_name
    instructor ? instructor.last_name : ''
  end

  def today
    date_for_zone(time_zone)
  end

  def now
    time_for_zone(time_zone)
  end

  def date_in_past?(a_date)
    date_time_from_parts(a_date, due_time, time_zone) < now
  end

  def allow_audio_transcripts?
    audio_transcript.nil? ? course.allow_audio_transcripts? : audio_transcript
  end

  def current_announcement_notifications(student)
    # Returns the last of dismissed and undismisssed notifications per announcement by using the
    # group_by clause on the notification results
    notifications.unscoped
        .joins("INNER JOIN announcements ON announcements.id = notifications.announcement_id")
        .where(user_id: student)
        .where("announcements.show_on = ?", date_for_zone(time_zone))
        .order('notifications.id ASC')
        .group_by(&:announcement_id).values.map(&:last)
  end

  def self.by_course_by_instructor(course_id, instructor)
    course = Course.find_by(id: course_id)
    if course&.is_enterprise? &&
      !course&.owned_by?(instructor) &&
      instructor.institution_admin?
      by_course(course_id)
    else
      by_course(course_id).by_instructor(instructor)
    end
  end

  def self.find_archived(id)
    unscoped.where(id: id, is_archived: 1)
  end

  def self.find_including_archived(ids = nil)
    return unscoped.find(ids) if ids
    unscoped.all
  end

  def self.find_in_open_courses_for_program(roster_ids, program_id)
    open.by_program(program_id).where(id: roster_ids)
  end

  def self.find_open_by_id(section_ids)
    open.where(id: section_ids)
  end

  def self.by_guid(guid)
    where(guid: guid).first
  end

  def editable_by?(user)
    user == instructor || user == course.owner || additional_co_instructor?(user)
  end

  #TODO: Rewrite to improve efficiency
  def activities_in_category(category)
    assignments.collect { |assignment|
      assignment.assignable if assignment.category.id == category.id
    }.compact.uniq
  end

  #TODO: Rewrite to improve efficiency
  def activities_in_week(week)
    week_to_date = Date.parse(week)
    return [] unless weeks_covered.include?(week_to_date)
    assignments.collect { |assignment|
      assignment.assignable if assignment.in_week(week_to_date)
    }.compact.uniq
  end

  #TODO: Rewrite to improve efficiency
  def activities_on_day(day)
    assignments.collect { |assignment|
      assignment.assignable if assignment.due_date == day
    }.compact.uniq
  end

  def activities
    assignments.collect{|assignment| assignment.assignable}
  end

  def school
    course.school
  end

  def program_id
    program.id
  end

  def enrollments_without_sufficient_access
    current_enrollments.where(sufficient_access: false)
  end

  def self.assignments_for_sections(sections, activities)
    assignments = []
    sections.each do |section|
      assignments << section.assignments_by_activities(activities) if section
    end
    assignments.flatten
  end

  def archived?
    self.is_archived
  end

  def archive
    one_roster_linked_section.archive if one_roster_linked_section.present?
    enrollments.archive
    # order of operations here is important!
    # Update attributes needs to be called first to propagate archived
    # section to UA, then we can archive all the section's section_instructor
    # records.

    # UA section update is handled by a Sidekiq worker after_save
    if update(is_archived: true)
      section_instructors.archive
    else
      errors.add(:base, 'Section deletion failed. Please try again in a few minutes. If you continue to see this error, please contact technical support.')
    end
  end

  def cumulative_grade_for(category)
    GradebookEngine::GradebookAPI.section_average(section: self, category: category) if non_zero?
  end

  def cumulative_grade
    GradebookEngine::GradebookAPI.section_average(section: self) if non_zero?
  end

  def students_for_cumulative_grade
    if course.is_demo?
      current_students_base
    else
      real_students_base
    end

  end
  private :students_for_cumulative_grade

  def activities_for_due_date(due_date)
    assignments.due_on(due_date).not_external.includes(:assignable).map(&:assignable)
  end

  def assignments_by_activities(activities)
    cache_key = Digest::SHA1.digest(activities.compact.map(&:id).sort.join)
    @assignments_by_activities = Hash.new unless defined?(@assignments_by_activities)
    @assignments_by_activities[cache_key] ||= assignments.where(Assignment.assignable_conditions(activities))
  end

  def assignment_past_due_count
    today = Date.today
    assignments.select { |a| a.due_date < today }.size
  end

  def first_five_students
    return [] unless current_students_base.present?
    current_students_base.order('last_name ASC').limit(5)
  end

  def first_five_active_students
    current_active_students_base.order('last_name ASC').limit(5)
  end

  def units(all_units_flag = nil)
    all_units_flag == 'true' ? program.browsable_units : units_covered
  end

  def covers_all_program_units?
    zero? || course.covers_all_program_units?
  end

  def additional_instructors
    section_instructors.reject { |section_instructor| section_instructor.user_id == course.owner_id }
  end

  def prospective_additional_instructors
    if course.owner.clever?
      all_potential_instructors.select(&:clever?)
    else
      all_potential_instructors
    end
  end

  private def all_potential_instructors
    section_instructor_ids = section_instructors.map(&:user_id)
    course.prospective_additional_instructors.reject do |instructor|
      section_instructor_ids.include?(instructor.id)
    end
  end

  def real_students_base
    current_students_base.reject { |st| st.fake? }
  end

  def set_instructor_team_ids
    self.instructor_team_ids = section_instructors.map(&:user_id).join(',')
  end
  private :set_instructor_team_ids

  def set_shared_false_if_template
    self.shared = !is_template?
  end
  private :set_shared_false_if_template

  def has_instructor?(user)
    instructors.any? { |instructor| instructor == user }
  end

  def owner_name_not_hidden_without_additional_instructors
    if hide_owner_name && additional_instructors.empty?
      errors.add(
        :additional_instructors,
        'To hide section owner name, at least a Co-Instructor or Assistant is required'
      )
    end
  end
  private :owner_name_not_hidden_without_additional_instructors

  # overrides is_deleted in the Etl module
  def is_deleted?
    archived? || super
  end

  # covers cases where we trigger the same behavior for
  # either RA courses or LTI-Adv rostered courses
  def autorostering_linked?
    one_roster_linked_section.present? ||
      lti_roster_linked?
  end

  def one_roster_linked?
    one_roster_linked_section.present?
  end

  def lti_roster_linked?
    lti_context_link.present? && instructor.lti_rostering?
  end

  def assignment_set_due_dates
    assignment_sets.map(&:due_date)
  end

  def additional_co_instructor?(user)
    additional_instructors.any? do |sec_instructor|
      sec_instructor.user_id == user.id &&
        sec_instructor.role == 'Co-instructor'
    end
  end

  private def enterprise_section_consistency
    if is_enterprise? && course && !course.is_enterprise?
      errors.add(:is_enterprise, 'an enterprise section must belong to an enterprise course')
    end
  end

  private def single_enterprise_section
    return unless is_enterprise?

    if !other_enterprise_sections.empty? || has_other_enterprise_section?
      errors.add(:is_enterprise, 'an enterprise course can only have one enterprise section')
    end
  end

  private def other_enterprise_sections
    course.sections.reject { |s| s == self }.select(&:is_enterprise)
  end

  private def has_other_enterprise_section?
    course.enterprise_section.present? && course.enterprise_section != self
  end
end
