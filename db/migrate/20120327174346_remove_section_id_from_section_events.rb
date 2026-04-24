class RemoveSectionIdFromSectionEvents < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :section_events, :section_id
  end

  def self.down
    add_column :section_events, :section_id, :integer
  end
end
