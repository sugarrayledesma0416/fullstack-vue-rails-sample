class AddSourceTemplateIdToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :source_template_id, :integer, default: nil
  end
end
