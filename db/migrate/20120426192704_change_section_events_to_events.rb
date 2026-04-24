class ChangeSectionEventsToEvents < ActiveRecord::Migration[4.2]
  def self.up
    rename_table :section_events, :events
  end

  def self.down
    rename_table :events, :section_events
  end
end
