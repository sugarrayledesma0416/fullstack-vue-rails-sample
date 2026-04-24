require 'institution_admin'

class School < ApplicationRecord
  include Dangerfield::Subscriber

  ONE_ROSTER_SSO_ROSTERING = 'SSO-Rostering'.freeze
  ONE_ROSTER_ROSTERING = 'Rostering'.freeze
  ONE_ROSTER_INTEGRATION_TYPES = [ONE_ROSTER_SSO_ROSTERING, ONE_ROSTER_ROSTERING, '', nil].freeze

  # This mapping is based on the mappings in self.category_from_school_type
  MARKET_CATEGORY_MAP = {
    'k-12' => [2, 3],
    'college-university' => [1],
    'international-other' => [4]
  }.freeze

  subscribe to: self
  self.dangerfield_exclude_on_update = %w(id updated_at created_at
                                          sales_rep_guid district_guid
                                          has_account_packages).freeze
  dangerfield_before_update :assign_related_objects

  # The country association is required unless country code is USA or CAN.
  # Those two codes don't have entries in the countries table.
  belongs_to :country, foreign_key: :country_code, primary_key: 'code', optional: true
  belongs_to :parent_institution, optional: true

  has_many :school_users

  has_many :students,
           (lambda do
             order('users.last_name, users.first_name ASC')
           end),
           through: :school_users,
           class_name: 'Student',
           foreign_key: 'user_id',
           source: :user

  has_many :instructors,
           through: :school_users,
           class_name: 'Instructor',
           foreign_key: 'user_id',
           source: :user

  has_many :courses
  has_many :site_licenses
  has_many :shared_library_activities
  has_many :school_program_admin_users
  has_many :one_roster_linked_users, class_name: 'OneRoster::LinkedUser'
  has_many :cartridge_course_context_details, class_name: 'Cartridge::CourseContextDetail',
                                              dependent: :destroy

  belongs_to :sales_rep, class_name: 'User', optional: true
  belongs_to :district, optional: true

  has_one :school_config, dependent: :destroy

  validates :time_zone, time_zone: true

  alias flipper_id id

  def self.find_guid(id)
    where(id: id).pluck(:guid).first
  end

  def self.by_guid(guid)
    find_by_guid(guid)
  end

  def find_district_guid
    if district_id.present?
      School.where(id: district_id).pluck(:guid).first
    end
  end

  def assign_related_objects(received_attrs)
    # always set these incoming values as either or both could change
    self.district_id = School.find_by_guid(received_attrs['district_guid']).id if received_attrs['district_guid'].present?
    self.sales_rep = User.find_by_guid(received_attrs['sales_rep_guid']) if received_attrs['sales_rep_guid'].present?
  end

  def prospective_students_for(sections)
    students
  end

  def real_students
    students.not_fake
  end

  def country_name
    return '' if ['USA','CAN'].include?(country_code) || country.nil?
    country.name
  end

  def self.category_from_school_type(school_type_name)
    case school_type_name
      when '4-Year College', '2-Year College', 'Online University' then 1
      when 'Private', 'Catholic', 'Catholic State', 'Private State' then 2
      when 'Public' then 3
      when 'Proprietary', 'International', 'Other', 'Continuing Ed', 'Prospect', 'District' then 4
      else nil
    end
  end

  def active_instructors_with_program_access(program)
    # This requires school / user association data as well as license data, so
    # we're using a maestro_client method which gets the data from API and UA.
    instructor_list = Maestro::School.instructors(guid, program.id)
    Instructor.where(id: instructor_list['instructor_ids'], archived: false)
  end

  def district?
    school_type.casecmp('District') == 0
  end

  def clever?
    clever_id.present?
  end

  def clever_rostering?
    clever_integration_type == 'Rostering'
  end

  def one_roster_rostering?
    one_roster_integration_type == ONE_ROSTER_SSO_ROSTERING || one_roster_integration_type == ONE_ROSTER_ROSTERING
  end

  def rostering?
    clever_rostering? || one_roster_rostering?
  end

  def enterprise_for_program?(program_id)
    SchoolProgramAdminUser.where(school_id: id, program_id: program_id).any?
  end

  def gradebook_analytics_enabled?
    M3::Application.config.flipper[:gradebook_analytics].enabled?(self)
  end

  def is_parent_institution?
    School.where(parent_institution_id: id).any?
  end

  def can_share_to_google_classroom?
    return share_to_google_classroom if district? || !district

    district_timestamp = district.share_to_google_classroom_last_updated_at
    self_timestamp = share_to_google_classroom_last_updated_at
    if district_timestamp > self_timestamp
      district.share_to_google_classroom
    else
      share_to_google_classroom
    end
  end

  # Returns true if the school has chat support enabled. If the school belongs
  # to a district, both the school and the district must have this support enabled.
  def has_chat_support_enabled?
    if district? || !district
      !school_config&.chat_support_disabled
    else
      !school_config&.chat_support_disabled && district.has_chat_support_enabled?
    end
  end

  def has_chat_support_disabled?
    !has_chat_support_enabled?
  end

  def school_content_sharing?
    school_config&.school_content_sharing != false
  end

  def program_content_sharing?(program_id)
    school_config&.program_content_sharing_json&.fetch(program_id.to_s, true) != false
  end

  def sharing_content_for_program?(program_id)
    return false if district&.school_content_sharing? == false

    school_content_sharing? && program_content_sharing?(program_id)
  end

  def k12?
    in_selected_market?('k-12')
  end

  private def in_selected_market?(market)
    return false if MARKET_CATEGORY_MAP[market].nil?

    MARKET_CATEGORY_MAP[market].include?(school_type_category)
  end
end
