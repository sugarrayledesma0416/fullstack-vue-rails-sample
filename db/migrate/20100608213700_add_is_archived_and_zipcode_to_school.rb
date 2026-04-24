class AddIsArchivedAndZipcodeToSchool < ActiveRecord::Migration[4.2]
  def self.up
    add_column :schools, :is_archived, :boolean , :default => false
    add_column :schools, :zip_code, :string , :limit=>12 
  end

  def self.down
    remove_column :schools, :is_archived
    remove_column :schools, :zip_code
  end
end
