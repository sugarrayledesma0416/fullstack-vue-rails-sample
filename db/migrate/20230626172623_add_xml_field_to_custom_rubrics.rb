class AddXmlFieldToCustomRubrics < ActiveRecord::Migration[6.1]
  def change
    add_column :custom_rubrics, :stored_rubric, :text
    add_column :custom_rubrics, :rubric_revision, :integer
  end
end
