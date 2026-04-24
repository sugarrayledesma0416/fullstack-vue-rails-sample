class CreateFeedbackItemAIComments < ActiveRecord::Migration[6.1]
  def change
    create_table :feedback_item_ai_comments do |t|
      t.belongs_to :feedback_item
      t.boolean :ai_generated_comment, default: false, null: false
      t.boolean :ai_generated_inline_corrections, default: false, null: false
      t.timestamps
    end
  end
end
