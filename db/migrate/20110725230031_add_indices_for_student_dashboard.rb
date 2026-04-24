class AddIndicesForStudentDashboard < ActiveRecord::Migration[4.2]
  def self.up
    add_index :assignments, :assignable_id
    add_index :assignments, :study_schedule_id
    add_index :attempts, :activity_id
    add_index :attempts, :user_id
    add_index :attempts, :section_id
    add_index :program_media_items, :program_id
    add_index :program_media_items, :media_item_id
    add_index :activities, :concept_id
    add_index :study_schedules, :section_id
  end

  def self.down
    remove_index :assignments, :assignable_id
    remove_index :assignments, :study_schedule_id
    remove_index :attempts, :activity_id
    remove_index :attempts, :user_id
    remove_index :attempts, :section_id
    remove_index :program_media_items, :program_id
    remove_index :program_media_items, :media_item_id
    remove_index :activities, :concept_id    
    remove_index :study_schedules, :section_id
  end
end
