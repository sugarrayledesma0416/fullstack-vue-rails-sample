class AddIgnoreCapitalizationToScoringRuleset < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scoring_rulesets, :ignore_capitalization, :boolean
  end

  def self.down
    remove_column :scoring_rulesets, :ignore_capitalization
  end
end
