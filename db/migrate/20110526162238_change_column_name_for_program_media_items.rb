class ChangeColumnNameForProgramMediaItems < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :program_media_items, :type, :media_type
  end

  def self.down
    rename_column :program_media_items, :media_type, :type
  end
end
