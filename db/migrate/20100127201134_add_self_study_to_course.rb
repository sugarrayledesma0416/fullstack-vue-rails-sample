class AddSelfStudyToCourse < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :self_study, :integer, limit: 1, null: false, default: 0
  end

  def self.down
    remove_column :courses, :self_study
  end
end
