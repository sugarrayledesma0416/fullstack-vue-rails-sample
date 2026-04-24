class AddSectionAndUserIndexToSectionInstructors < ActiveRecord::Migration[4.2]
  def self.up
    add_index :section_instructors, [:section_id, :user_id], :name => 'by_section_and_user'
  end

  def self.down
    remove_index :section_instructors, :name => :by_section_and_user
  end
end
