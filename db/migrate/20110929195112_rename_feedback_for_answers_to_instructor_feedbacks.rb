class RenameFeedbackForAnswersToInstructorFeedbacks < ActiveRecord::Migration[4.2]
  def self.up
    rename_table :feedback_for_answers, :feedback_items
  end

  def self.down
    rename_table :feedback_items, :feedback_for_answers
  end
end
