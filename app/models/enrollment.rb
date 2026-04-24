class Enrollment < ApplicationRecord
  include Dangerfield::Subscriber
  include Dangerfield::Publisher
  include Etl
  include Enterprise::SectionValidation

  belongs_to :user
  belongs_to :section

  has_one :course, :through => :section

  # dangerfield subscriber support
  subscribe to: self
  dangerfield_exclude_on_update %w(id updated_at created_at section_guid user_guid added_by_guid
                                   transferred_from_guid section_transferred_to_guid dropped_by_guid)

  dangerfield_before_update :assign_related_objects
  dangerfield_reject_if :no_user_or_no_section_added?
  dangerfield_skip_save_if :archived_section?

  after_commit :lock_and_process_section_data, on: :create
  after_commit :update_gradebook

  scope :with_eager_load, -> { includes(section: [{ course: :program }, :instructor]) }
  scope :by_program, ->(program) { where(courses: { program_id: program }).joins(section: :course) }

  scope :transferred, -> { where(state: 'transferred') }
  scope :transferred_or_dropped, -> { where(state: %w[transferred dropped]) }
  scope :active, -> { where(state: 'enrolled') }
  scope :sufficient_access, -> { where(sufficient_access: true) }

  scope :active_or_completed, -> { where(state: %w[enrolled marked_complete]) }

  scope :by_section, ->(section) { where(section_id: section) }
  scope :by_section_transferred_to, ->(section) { where(section_transferred_to: section) }
  scope :by_student, ->(student) { where(user_id: student) }

  scope :in_open_course, lambda {
    where('sections.is_archived = 0 AND courses.is_archived = 0 ' \
          'AND courses.end_date >= ?', Time.zone.now.to_date)
      .select('enrollments.*')
      .joins(section: :course)
  }

  scope :in_editable_course, lambda {
    where('sections.is_archived = ? AND courses.is_archived = ? AND courses.end_date >= ?',
          false, false, Time.zone.now.to_date - 1.month)
      .select('enrollments.*')
      .joins(section: :course)
  }
  validate :require_student

  validates_inclusion_of :state, :in => ['enrolled', 'marked_complete', 'dropped', 'transferred', 'archived', 're-enrolled']

  def self.active_in_open_course(eager_load = {})
    active.in_open_course.includes(eager_load)
  end

  def self.active_in_editable_course(eager_load = {})
    active_or_completed.in_editable_course.includes(eager_load)
  end

  def self.active_or_completed_in_open_course
    active_or_completed.in_open_course.includes(:section)
  end

  def self.active_or_completed_in_editable_course
    active_or_completed.in_editable_course.includes(:section)
  end

  def self.active_or_completed_in_open_course_by_section(sections)
    by_section(sections).active_or_completed_in_open_course
  end

  def self.active_or_completed_in_editable_course_by_section(sections)
    by_section(sections).active_or_completed_in_editable_course
  end

  def self.by_section_and_student(section, student)
    by_section(section).by_student(student)
  end

  # find the course, ignoring is_archived
  def associated_course
    associated_section = Section.unscoped.find(section_id)
    Course.unscoped.find(associated_section.course_id)
  end

  def active?
    return false unless section && section.course
    return false if section.is_archived || section.course.is_archived
    enrolled? && !complete?
  end

  def inactive?
    !active?
  end

  def complete?
    state == 'marked_complete' || (enrolled? && section.closed?)
  end

  def dropped?
    state == 'dropped'
  end

  def transferred?
    state == 'transferred'
  end

  def archived?
    state == 'archived'
  end

  def archived_section?(_received_attrs)
    unscoped_section = Section.unscoped.find_by(id: section_id)
    unscoped_section&.is_archived?
  end

  def self.enroll_demo_students(students, section)
    enroll(students, section)
    students.each do |student|
      m3_enrollments = where(user_id: student.id, section_id: section.id)

      if Rails.env.live? # we want to raise errors on live
        raise "no m3 enrollments" if m3_enrollments.empty?
        raise "no active m3 enrollments" if m3_enrollments.none? { |enrollment| enrollment.enrolled? }
      end

      m3_enrollments.select(&:enrolled?).each(&:unblock_access!)
    end
  end

  def self.enroll(students, section)
    enrolled_students = Hash.new { |k, v| k[v] = [] }

    students_guids = students.collect(&:guid)
    upgraded_student_guids = Maestro::EditionUpgrade
                             .grant_users(students_guids, section.course.guid)
                             .upgraded_user_guids
    # UA will log edition upgrade events by student.
    begin
      Ua::UserLogEntries.create(students_guids: upgraded_student_guids, section_guid: section.guid)
    rescue ActiveResource::ServerError => e
      Rails.logger.warn "UA returned bad response: #{e.message} during creates " \
                        'logging to edition upgrade for students'
    end

    students.each do |student|
      enroller = EnrollmentEngine::Enroller.new(
        student,
        section,
        enroll_by: EnrollmentEngine::ENROLL_BY_INSTRUCTOR
      ).enroll
      status_tag = if enroller.errors.empty?
                     student.sufficient_access_for_course?(section) ? :success : :insufficient_access
                   else
                     enroller.errors[:hard_cap] && enroller.errors[:hard_cap].present? ? :hard_cap_reached : :failed
                   end
      enrolled_students[status_tag] << student
    end

    enrolled_students
  end

  def self.undrop_student(user_id, section_id)
    return unless section_id
    unless (enrollment = find_by_user_id_and_section(user_id, section_id)).nil?
      enrollment.undrop
      enrollment.reload
    end
  end

  def self.drop_student(user_id, section_id)
    return unless section_id
    enrollment = find_active_or_completed_by_user_id_and_section(user_id, section_id) ||
      find_by_user_id_and_section(user_id, section_id)
    if enrollment
      enrollment.drop
      enrollment.reload
    end
  end

  def self.find_active_or_completed_by_user_id_and_section(student, section)
    by_student(student).by_section(section).active_or_completed.order('id desc').first
  end

  def self.find_by_user_id_and_section(student_id, section)
    by_student(student_id).by_section(section).order('id desc').first
  end

  def self.find_all_active_or_completed_by_users_and_sections(students, sections)
    by_student(students).by_section(sections).active_or_completed.order('id desc')
  end

  def self.find_all_enrolled_by_users_and_sections(students, sections)
    by_student(students).by_section(sections).active
  end

  def archive!
    update!(state: 'archived')
  end

  def undrop
    update!(state: 'enrolled')
  end

  def drop
    update!(state: 'dropped', dropped_at: Time.zone.now)
  end

  def transfer(section_to)
    update!(state: 'transferred', section_transferred_to: section_to.id)
  end

  def mark_complete
    update!(state: 'marked_complete')
  end

  def program
    section.program if section && !section.is_archived?
  end

  def lockable?
    enrolled? && errors.empty? && !for_demo_purposes?
  end

  def transferred_from_section
    Section.find_including_archived(transferred_from) if was_transferred?
  end

  def was_transferred?
    transferred_from && # dont bother if enrollment was not a transfer
    section_id != transferred_from # dont bother if we just dropped to enroll back(or undo)
  end

  def previous_section
    transferred_from_section || Section.section_zero
  end

  def lock_and_process_section_data
    return unless lockable?
    StudentWorkTransferWorker.perform_async(user.id, previous_section.id, section_id)
    MissingAnnouncementCreatorWorker.perform_async(user_id, section_id)
  end

  def block_access!
    self.blocked = true
    self.save!
  end

  def unblock_access!
    self.blocked = false
    self.save!
  end

  def require_student
    unless user.student?
      errors.add(:user, 'must be a student')
    end
  end
  private :require_student

  def enrolled?
    state == 'enrolled'
  end

  def for_demo_purposes?
    user.fake? && course.is_demo?
  end

  # Rostering support
  # adding a new instance via subscription;
  # before saving need to look up related objects by guid and add them
  # so their ids get stored with the new instance.
  # because of the way that dangerfield works this method
  # will also be called when an existing object is receiving
  # an update from rostering so check if it has an id
  # before proceeding.
  def assign_related_objects(received_attrs)
    if new_record?
      self.section = Section.find_by_guid(received_attrs['section_guid'])
      self.user = User.find_by_guid(received_attrs['user_guid'])
      self.added_by_id = User.unscoped.find_by_guid(received_attrs['added_by_guid']).id if received_attrs['added_by_guid'].present?
      self.transferred_from = Section.unscoped.find_by_guid(received_attrs['transferred_from_guid']).id if received_attrs['transferred_from_guid'].present?
    end
    # attributes that can change on an enrollment
    self.dropped_by_id = User.unscoped.find_by_guid(received_attrs['dropped_by_guid']).id if received_attrs['dropped_by_guid'].present?
    self.section_transferred_to = Section.unscoped.find_by_guid(received_attrs['section_transferred_to_guid']).id if received_attrs['section_transferred_to_guid'].present?
  end

  # ensure that both the section and the user have been added to the database
  # the latter can occur if it is a sample student and the push to add user
  # has not been processed yet. This will allow dangerfield to reject the push
  # of the enrollment and SNS will retry.
  def no_user_or_no_section_added?(received_attrs)
    no_user_added?(received_attrs) || no_section_added?(received_attrs)
  end

  def no_user_added?(received_attrs)
    received_attrs['user_guid'].nil? || User.find_by_guid(received_attrs['user_guid']).nil?
  end

  def no_section_added?(received_attrs)
    received_attrs['section_guid'].nil? || Section.find_by_guid(received_attrs['section_guid']).nil?
  end

  # overrides of methods in Etl module

  # when the Enrollment is added/updated in Gradebook db,
  # update the user in case s/he is not there
  def update_gradebook
    if is_deleted?
      notify_deletion
    else
      notify_update
      self.user.update_gradebook
    end
  end

  def is_deleted?
    dropped? || transferred? || archived? || super
  end

  def gb_deletion_opts
    { :model_name => self.gradebook_class_name, :id => self.id, :section_id => self.section_id, :user_id => self.user_id, :action => 'delete' }
  end

  # end Etl module overrides
end
