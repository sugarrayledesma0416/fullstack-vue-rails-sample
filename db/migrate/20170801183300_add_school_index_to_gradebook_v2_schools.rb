class AddSchoolIndexToGradebookV2Schools < ActiveRecord::Migration[4.2]
  def change
    add_index :gradebook_v2_schools, [:school_id], name: 'idx_gradebook_v2_schools_school'
  end
end
