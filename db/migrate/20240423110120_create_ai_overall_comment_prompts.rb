class CreateAIOverallCommentPrompts < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_overall_comment_prompts do |t|
      t.text :template_body, null: false
      t.string :model, null: false
      t.float :temperature

      t.timestamps
    end
  end
end
