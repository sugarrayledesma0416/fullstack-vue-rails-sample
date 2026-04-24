class AddAssessmentToConcept < ActiveRecord::Migration[4.2]
  def self.up
    add_column :concepts, :assessment, :boolean, :default => false
  end

  def self.down
    remove_column :concepts, :assessment
  end
end
