class AddActivityRevisionIdAndStrandIdToCustomRubrics < ActiveRecord::Migration[6.1]
  def change
    add_column :custom_rubrics, :activity_revision_id, :integer
    add_column :custom_rubrics, :strand_id, :integer
  end
end
