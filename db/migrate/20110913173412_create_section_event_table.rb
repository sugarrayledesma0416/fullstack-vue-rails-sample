class CreateSectionEventTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :section_events do |t|
      t.integer  "section_id"
      t.string   "name"
      t.date     "date"
      t.integer  "added_by"

      t.timestamps
    end
  end

  def self.down
    drop_table :section_events
  end
end
