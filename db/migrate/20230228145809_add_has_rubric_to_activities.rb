class AddHasRubricToActivities < ActiveRecord::Migration[6.1]
  def change
    add_column :activities, :has_rubric, :boolean
  end
end
