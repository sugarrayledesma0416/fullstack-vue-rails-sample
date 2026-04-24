class AddIsClassCancelledToSectionEvent < ActiveRecord::Migration[4.2]
  def self.up
    add_column :section_events, :class_cancelled, :boolean, :default => false
  end

  def self.down
    remove_column :section_events, :class_cancelled
  end
end
