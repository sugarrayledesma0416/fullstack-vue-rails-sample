class RenameAddedByToUserIdInSectionEvents < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :section_events, :added_by, :user_id
  end

  def self.down
    rename_column :section_events, :user_id, :added_by
  end
end
