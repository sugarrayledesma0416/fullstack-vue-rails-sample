class AddEditedToAIOverallComments < ActiveRecord::Migration[6.1]
  def change
    add_column(
      :ai_overall_comments,
      :edited,
      :boolean,
      default: false
    )
  end
end
