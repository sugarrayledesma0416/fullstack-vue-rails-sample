class CreateHelpEntry < ActiveRecord::Migration[4.2]
  def self.up
    create_table :help_entries do |t|
      t.string  :page
      t.string  :url
      t.timestamps
    end
  end

  def self.down
    drop_table :help_entries
  end
end
