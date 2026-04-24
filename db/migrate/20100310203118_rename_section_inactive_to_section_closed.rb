class RenameSectionInactiveToSectionClosed < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :sections, :inactive, :closed
  end

  def self.down
    rename_column :sections, :closed, :inactive
  end
end
