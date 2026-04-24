class CreateFeedbackForAnswers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :feedback_for_answers do |t|
      t.integer :attempt_id
      t.string  :question_label
      t.float   :points_earned
      t.text    :inline_corrections
      t.text    :comment
      t.integer :user_id
      t.integer :section_id

      t.timestamps
    end    
  end

  def self.down
    drop_table :feedback_for_answers
  end
end
