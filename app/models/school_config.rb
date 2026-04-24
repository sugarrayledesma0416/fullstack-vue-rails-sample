class SchoolConfig < ApplicationRecord
  include Dangerfield::Publisher
  include Dangerfield::Subscriber
  include Etl

  subscribe to: self

  dangerfield_exclude_on_update %w[school_guid]
  dangerfield_before_update :assign_related_objects

  belongs_to :school

  serialize :program_content_sharing_json, JSON

  validates :school_id, uniqueness: true
  validates :school_content_sharing, inclusion: { in: [true, false] }
  validate :program_content_sharing_json_must_be_valid
  validate :district_cannot_have_program_content_sharing

  after_save :disable_chat_in_courses

  def assign_related_objects(received_attrs)
    self.school = School.find_by(guid: received_attrs['school_guid'])
  end

  def program_content_sharing_json
    super || {}
  end

  # program_content_sharing_json must have a json as a hash with the following structure
  # key: must be program_id as a numeric string
  # value: must be a boolean indicating whether or not content can be shared for that program
  private def program_content_sharing_json_must_be_valid
    return if program_content_sharing_json_valid?

    errors.add(
      :program_content_sharing_json,
      'must be a valid JSON object with integer string keys and boolean values'
    )
  end

  private def program_content_sharing_json_valid?
    return true if program_content_sharing_json.nil?

    return false unless program_content_sharing_json.is_a?(Hash)

    number_regex = /\A\d+\z/

    program_content_sharing_json.all? do |key, value|
      key.is_a?(String) && key.match?(number_regex) && [true, false].include?(value)
    end
  end

  private def district_cannot_have_program_content_sharing
    return unless school.district? && program_content_sharing_json.present?

    errors.add(
      :program_content_sharing_json,
      'content cannot be shared by program for a District'
    )
  end

  private def disable_chat_in_courses
    return unless chat_support_disabled

    school.courses.open.where.not(chat_level: 'disabled').find_each do |course|
      course.update!(chat_level: 'disabled')
    end
  end
end
