# encoding:  utf-8
class User < ApplicationRecord
  include Dangerfield::Subscriber
  include Etl

  self.inheritance_column = 'account_type'

  # dangerfield subscriber support
  subscribe to: self

  default_scope { where('`users`.archived = 0') }

  has_many :announcements
  has_many :enrollments
  has_many :sections, :through => :enrollments

  has_many :school_users
  has_many :schools,
           -> { order('school_users.created_at, school_users.id') },
           through: :school_users
  has_many :schools_with_countries,
           -> { order('school_users.created_at, school_users.id').includes(:country) },
           source: :school,
           through: :school_users

  has_many :help_entries
  has_many :roles_users, :dependent => :destroy
  has_many :roles, :through => :roles_users

  has_one :assignment_filter

  has_many :settings

  has_many :notifications

  has_many :recordings

  has_many :help_requests

  has_many :server_error_reports

  has_many :user_defined_words

  has_many :readings, class_name: 'UserReading', dependent: :destroy
  has_many :school_program_admin_users

  has_one :one_roster_linked_user, class_name: 'OneRoster::LinkedUser'

  has_many :lti_user_link, class_name: 'Lti::UserLink'

  has_many :student_section_configs, dependent: :destroy

  after_commit :update_gradebook

  scope :not_fake, -> { where(fake: false) }
  scope :is_fake, -> { where(fake: true) }
  attr_writer :imported_account
  attr_writer :auto_created_m3_account

  ACCOUNT_TYPES = %w[Student Instructor InstitutionAdmin DataAdmin Grader Editor].freeze
  CLEVER_USERS_FAKE_EMAIL_DOMAIN = 'this-is-a-clever-user.com'.freeze
  CLEVER_ADMIN_USERS_FAKE_EMAIL_DOMAIN = 'this-is-a-clever-admin-user.com'.freeze
  CLEVER_USERS_FAKE_EMAIL_DOMAINS = [
    CLEVER_USERS_FAKE_EMAIL_DOMAIN,
    CLEVER_ADMIN_USERS_FAKE_EMAIL_DOMAIN
  ].freeze
  ONE_ROSTER_USERS_FAKE_EMAIL_DOMAIN = 'this-is-an-ra-user.com'.freeze
  CARTRIDGE_USERS_FAKE_EMAIL_DOMAIN = 'this-is-a-cartridge-user.com'.freeze
  LTI_USERS_FAKE_EMAIL_DOMAIN = 'this-is-an-lti-user.com'.freeze
  # List of email domains for Lti users
  LTI_USERS_FAKE_EMAIL_DOMAINS = [
    LTI_USERS_FAKE_EMAIL_DOMAIN, # native Lti user
    ONE_ROSTER_USERS_FAKE_EMAIL_DOMAIN, # RA user transitioned to Lti-rostering
    CLEVER_USERS_FAKE_EMAIL_DOMAINS # Clever user transitioned to Lti-rostering
  ].flatten.freeze

  def self.find_guid(id)
    where(id: id).pluck(:guid).first
  end

  def username=(val)
    val = val.downcase.strip unless val.nil?
    write_attribute(:username, val)
  end

  # This is necessary because the email for clever users is a fake.
  # And the model requires this field not null and unique.
  def email
    if clever?
      ''
    elsif one_roster?
      one_roster_linked_user.email
    else
      read_attribute(:email)
    end
  end

  # should make this a named scope!
  def programs
    accessible_programs
  end

  def demo_only?
    [21, 1782, 125430, 125431, 129250, 134534, 831486].include?(id)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def last_name_first
    "#{last_name}, #{first_name}"
  end

  def sortable_name
    "#{last_name}#{first_name}".downcase
  end

  def full_name_initials
    first_initial = first_name.titleize.split.first[0]
    last_initial = last_name.titleize.split.first[0]
    [first_initial, last_initial].join('')
  end

  def initials_and_last_name
    first_name_initials = first_name.titleize.split(' ').collect{ |name| name.first }.join('.')
    [first_name_initials, last_name.titleize].join(' ')
  end

  def instructor?
    base_account_type == 'Instructor'
  end

  def institution_admin?
    account_type == 'InstitutionAdmin'
  end

  def data_admin?
    account_type == 'DataAdmin'
  end

  def enterprise_admin?
    institution_admin? || data_admin?
  end

  # Returns user's admin status for a given school.
  #
  # False by default; overridden by InstitutionAdmin.
  def admin_for_school?(school)
    false
  end

  def student?
    base_account_type == 'Student'
  end

  def grader?
    account_type == 'Grader'
  end

  def editor?
    account_type == 'Editor'
  end

  def is_resource_editor?
    has_role?(Role::RESOURCE_EDITOR)
  end

  def can_view_unreleased_units?
    has_role?(Role::UNRELEASED_UNIT_VIEWER)
  end

  def can_review_questions?
    has_role?(Role::REVIEWER)
  end

  def is_common_cartridge_creator?
    has_role?(Role::COMMON_CARTRIDGE_CREATOR)
  end

  def developer?
    has_role?(Role::DEVELOPER)
  end

  def ai_developer?
    has_role?(Role::AI_DEVELOPER)
  end

  def ai_grading_editor?
    has_role?(Role::AI_GRADING_EDITOR)
  end

  def clever?
    # This is a hack so we don't have to make calls to UA, who actually has
    # DB records to indicate when users are from Clever. This is set in UA:
    # - User::CLEVER_USERS_FAKE_EMAIL_DOMAIN
    # - User::CLEVER_ADMIN_USERS_FAKE_EMAIL_DOMAIN
    CLEVER_USERS_FAKE_EMAIL_DOMAINS.include?(email_domain) && !lti_rostering_user_link.present?
  end

  def clever_instructor?
    instructor? && email_domain == CLEVER_USERS_FAKE_EMAIL_DOMAIN && !lti_rostering_user_link.present?
  end

  def clever_admin?
    instructor? && email_domain == CLEVER_ADMIN_USERS_FAKE_EMAIL_DOMAIN && !lti_rostering_user_link.present?
  end

  def one_roster?
    # We first check the email domain no avoid unecessary DB calls.
    email_domain == ONE_ROSTER_USERS_FAKE_EMAIL_DOMAIN && one_roster_linked_user.present?
  end

  def cartridge?
    # We first check the email domain no avoid unecessary DB calls.
    email_domain == CARTRIDGE_USERS_FAKE_EMAIL_DOMAIN && cartridge_user_link.present?
  end

  def cartridge_user_link
    return @cartridge_user_link if defined? @cartridge_user_link

    @cartridge_user_link = Cartridge::UserLink.find_by(
      user_id: id, school_id: schools.first&.id
    )
  end

  def lti_rostering?
    LTI_USERS_FAKE_EMAIL_DOMAINS.include?(email_domain) &&
      lti_rostering_user_link.present?
  end

  def lti_rostering_transitioned_from_clever?
    lti_rostering? &&
      lti_rostering_user_link.lti_platform.rostering_transition_from_clever?
  end

  def lti_rostering_user_link
    return @lti_rostering_user_link if defined? @lti_rostering_user_link

    @lti_rostering_user_link = Lti::UserLink.where(
      user_id: id
    ).joins(
      :lti_platform
    ).where(
      lti_platforms: { rostering: true }
    ).first
  end

  def clever_rostering?
    # all schools for a clever rostering user will have this setting
    # so we only need to check the first one.
    clever? && schools.any?(&:clever_rostering?)
  end

  def one_roster_rostering?
    one_roster?
  end

  def rostering?
    clever_rostering? || one_roster_rostering? || lti_rostering?
  end

  def clever_or_one_roster?
    clever? || one_roster_rostering?
  end

  def has_role?(role)
    roles.map(&:name).include?(role)
  end
  private :has_role?

  def program_ids
    programs.collect(&:id)
  end

  def active_sections
    []
  end

  def accessible_programs
    # A `find` won't work here since the array of program ids returned
    # from the client may contain M2 only programs that are not
    # present in the M3 database.
    @accessible_programs ||= Program.where(id: Maestro::User.accessible_programs(guid).map(&:id))
  end

  def has_current_access_to?(program)
    accessible_programs.any? do |accessible_program|
      program.id == accessible_program.id
    end
  end

  def imported_account?
   @imported_account or false
  end

  def auto_created_m3_account?
    @auto_created_m3_account or false
  end

  def email_domain
    read_attribute(:email).split("@").last
  end

  def self.find_by_first_and_last_name(f_name,l_name)
    where(first_name: f_name, last_name: l_name)
  end

  def self.find_without_default_scope(*args)
    unscoped.find(*args)
  end

  def self.find_archived(id)
    unscoped.where(id: id, archived: true).first
  end

  def self.find_by_id_including_archived(user_id)
    unscoped.find_by_id(user_id)
  end

  # Retrieves a user's setting.
  def setting(name)
    settings_collection.get(name)
  end

  # Sets a setting.
  def set(name, value)
    settings_collection.set(name, value)
  end

  def has_active_courses_for_program?(program_id)
    false
  end

  def show_auto_graded_questions
    setting(Setting::GradingTasks::ShowAutoGradedQuestions)
  end

  def show_auto_graded_questions=(show_auto_graded_questions)
    set(Setting::GradingTasks::ShowAutoGradedQuestions, show_auto_graded_questions)
  end

  def grading_style
    setting(Setting::GradingTasks::GradingStyle)
  end

  def grading_style=(grading_style)
    set(Setting::GradingTasks::GradingStyle, grading_style)
  end

  def can_use_ai_grading_suggestions?
    setting(Setting::AI::AllowGradingSuggestions) == 'true'
  end

  def revoke_access_to_ai_grading_suggestions
    set(Setting::AI::AllowGradingSuggestions, 'false')
  end

  def grant_access_to_ai_grading_suggestions
    set(Setting::AI::AllowGradingSuggestions, 'true')
  end

  def enable_ai_grading_suggestions
    setting(Setting::AI::EnableGradingSuggestions)
  end

  def enable_ai_grading_suggestions=(enable_ai_grading_suggestions)
    set(Setting::AI::EnableGradingSuggestions, enable_ai_grading_suggestions)
  end

  def ai_grading_suggestions_enabled?
    setting(Setting::AI::EnableGradingSuggestions) == 'true'
  end

  def self.find_by_username_or_email(username)
    return find_by_email(username) if username =~ /^.+@.+$/
    find_by_username(username)
  end

  def avatar_image_url
    AvatarService.image_url(guid)
  end

  def avatar_thumb_url
    AvatarService.thumb_url(guid)
  end

  # overrides is_deleted in the Etl module
  def is_deleted?
    archived? || super
  end

  # need User sent to gradebook not Student or Instructor
  def gradebook_class_name
    "User"
  end

  # These methods are used by instructor/student models.
  protected def pubnub_course_info(course, sections)
    {
      chat_level: course.chat_level,
      id: "course_#{course.id}",
      name: course.name,
      program_id: course.program_id,
      sections: pubnub_section_info(sections)
    }
  end

  protected def pubnub_section_info(pubnub_sections)
    pubnub_sections.map do |section|
      {
        id: "section_#{section.id}",
        name: section.name,
        users: pubnub_section_users_for(section)
      }
    end
  end

  protected def pubnub_section_users_for(section)
    # Select all students and co-instructors. Not include current user in results
    users = (section.current_students + section.instructors).select { |i| i.id != id }

    users.map do |user|
      { uuid: user.id.to_s, first_name: user.first_name, last_name: user.last_name }
    end
  end

  protected def pubnub_grants_hash(sections_to_grant)
    {
      roster: {
        groups: sections_to_grant.map do |section|
          { id: "section_#{section.id}", name: section.name }
        end
      },
      user: { uuid: id.to_s, name: username }
    }
  end

  protected def pubnub_client_roster_hash(pubnub_courses)
    {
      roster: { groups: pubnub_courses },
      user: {
        first_name: first_name,
        last_name: last_name,
        name: username,
        uuid: id.to_s
      }
    }
  end

  private

  def settings_collection
    @settings_collection ||= Setting::Collection.new(self)
  end
end
