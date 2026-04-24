class AddIgnoreAccentsToScoringRuleset < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scoring_rulesets, :ignore_accents, :boolean
    add_column :scoring_rulesets, :ignore_punctuation, :boolean
  end

  def self.down
    remove_column :scoring_rulesets, :ignore_punctuation
    remove_column :scoring_rulesets, :ignore_accents
  end
end
