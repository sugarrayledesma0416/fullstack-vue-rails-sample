module Cartridge
  class CourseContextDetail < ApplicationRecord
    self.table_name = 'cartridge_course_context_details'
    belongs_to :course
    belongs_to :section
    belongs_to :school

    default_scope { where(is_archived: false) }

    validates :lms_context_id, presence: true

    def update_lis_outcome_service_url(url)
      update(lis_outcome_service_url: url)
    end

    def update_line_items_url(url)
      update(line_items_url: url)
    end
  end
end
