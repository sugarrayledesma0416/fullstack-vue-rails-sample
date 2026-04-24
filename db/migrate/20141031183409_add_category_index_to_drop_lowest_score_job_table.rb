class AddCategoryIndexToDropLowestScoreJobTable < ActiveRecord::Migration[4.2]
  def change
    add_index :drop_lowest_score_jobs, :category_id
  end
end
