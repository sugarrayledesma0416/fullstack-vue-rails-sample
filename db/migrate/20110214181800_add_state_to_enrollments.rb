class AddStateToEnrollments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :enrollments, :state, :string, :default => 'enrolled'
  end

  def self.down
    remove_column :enrollments, :state
  end
end
