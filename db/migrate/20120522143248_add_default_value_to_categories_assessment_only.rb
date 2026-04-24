class AddDefaultValueToCategoriesAssessmentOnly < ActiveRecord::Migration[4.2]
  def self.up
    change_column :categories, :assessment_only, :boolean, :default => false, :null => false
  end

  def self.down
    change_column :categories, :assessment_only, :boolean
  end
end
