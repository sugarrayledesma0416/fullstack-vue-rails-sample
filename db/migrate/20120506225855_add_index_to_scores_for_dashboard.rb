class AddIndexToScoresForDashboard < ActiveRecord::Migration[4.2]
  def self.up
    add_index :scores, [:user_id,:section_id,:submitted_at], :name => 'by_user_section_and_submitted_at'
  end

  def self.down
    remove_index :scores, :name => :by_user_section_and_submitted_at
  end
end
