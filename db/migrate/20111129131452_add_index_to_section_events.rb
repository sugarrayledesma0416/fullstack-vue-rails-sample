class AddIndexToSectionEvents < ActiveRecord::Migration[4.2]
  def self.up
    add_index :section_events, :date
  end

  def self.down
    remove_index :section_events, :date
  end
end
