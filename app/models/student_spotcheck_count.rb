class StudentSpotcheckCount < ApplicationRecord
  belongs_to :user
  belongs_to :section

  def self.create_or_update(student_ids, section_id)
    student_ids.each do |student_id|
      spotcheck_count = find_or_initialize_by(user_id: student_id, section_id:)
      spotcheck_count.count = spotcheck_count.new_record? ? 1 : spotcheck_count.count + 1
      spotcheck_count.save!
    end
  end
end
