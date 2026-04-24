class AddFieldEnhancedFeedbackDisabledToCategory < ActiveRecord::Migration[4.2]
  def self.up
    add_column :categories, :enhanced_feedback_disabled, :boolean, :default => false
  end

  def self.down
    remove_column :categories, :enhanced_feedback_disabled
  end
end
