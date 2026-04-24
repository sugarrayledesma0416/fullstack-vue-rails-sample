class CreateFileTypesTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :file_types do |t|
      t.string    :extension_name, :null => false
      t.string    :extension_description, :null => false
      t.integer   :is_archived, :default => 0
      t.integer   :is_allowed, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :file_types
  end
end
