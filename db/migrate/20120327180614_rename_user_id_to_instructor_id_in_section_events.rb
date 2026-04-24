class RenameUserIdToInstructorIdInSectionEvents < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :section_events, :user_id, :instructor_id
  end

  def self.down
    rename_column :section_events, :instructor_id, :user_id
  end
end
