class AddLessonCombinedRankToConcept < ActiveRecord::Migration[4.2]
  def change
    add_column :concepts, :lesson_combined_rank, :integer, null: false, default: 0
  end
end
