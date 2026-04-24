class CreateScoringRulesetTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :scoring_rulesets do |scoring_rules|
      scoring_rules.integer :course_gradebook_category_id
      scoring_rules.timestamps
    end
    
    add_column :attempts, :scoring_ruleset_id, :integer
    add_column :course_gradebook_categories, :current_scoring_ruleset_id, :integer
  end

  def self.down
    remove_column :course_gradebook_categories, :current_scoring_ruleset_id
    remove_column :attempts, :scoring_ruleset_id
    drop_table :scoring_rulesets
  end
end
