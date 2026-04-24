class AddActiveForInstructorGradingToAIOverallCommentPrompts < ActiveRecord::Migration[6.1]
  def change
    add_column(
      :ai_overall_comment_prompts,
      :active_for_instructor_grading,
      :boolean,
      default: false
    )
  end
end
