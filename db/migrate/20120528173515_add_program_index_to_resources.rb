class AddProgramIndexToResources < ActiveRecord::Migration[4.2]
  def self.up
    add_index :resources, :program_id
  end

  def self.down
    remove_index :resources, :program_id
  end
end
