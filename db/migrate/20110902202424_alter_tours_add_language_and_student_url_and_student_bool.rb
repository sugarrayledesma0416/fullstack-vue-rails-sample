class AlterToursAddLanguageAndStudentUrlAndStudentBool < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :tours, :url
    add_column :tours, :student, :boolean, :default => false
    add_column :tours, :language, :string
    add_column :tours, :instructor_url, :string 
    add_column :tours, :student_url, :string 
  end

  def self.down
  end
end
