class AttachStudySchedulesToSections < ActiveRecord::Migration[4.2]
  def self.up
    add_column :study_schedules, :section_id, :integer
  end

  def self.down
    remove_column :study_schedules, :section_id
  end
end
