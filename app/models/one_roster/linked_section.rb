module OneRoster
  class LinkedSection < ApplicationRecord

    default_scope { where(is_archived: false) }

    include Dangerfield::Publisher
    SEPARATOR = '::'.freeze

    self.table_name = 'one_roster_linked_sections'
    belongs_to :section
    belongs_to :school, optional: true

    validates :course_external_id, :class_external_id, presence: true
    serialize :academic_session, JSON

    def self.build_identifier(course_external_id, class_external_id)
      course_external_id.to_s + SEPARATOR + class_external_id.to_s
    end

    def archive
      update(is_archived: true)
    end

    def identifier
      {
        self.class.build_identifier(course_external_id, class_external_id) => section
      }
    end
  end
end
