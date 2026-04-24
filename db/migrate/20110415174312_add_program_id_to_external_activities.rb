class AddProgramIdToExternalActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :external_activities , :program_id , :integer
  end

  def self.down
    remove_column :external_activities , :program_id 
  end
end
