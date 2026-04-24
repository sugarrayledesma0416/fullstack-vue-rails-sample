class RemoveProgramIdFromLessons < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :lessons, :program_id
  end

  def self.down
    add_column :lessons, :program_id, :integer
  end
end
