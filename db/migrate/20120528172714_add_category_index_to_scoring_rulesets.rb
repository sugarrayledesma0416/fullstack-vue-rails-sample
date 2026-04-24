class AddCategoryIndexToScoringRulesets < ActiveRecord::Migration[4.2]
  def self.up
    add_index :scoring_rulesets, :category_id
  end

  def self.down
    remove_index :scoring_rulesets, :category_id
  end
end
