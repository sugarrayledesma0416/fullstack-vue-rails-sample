class AddIsTemplateToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :is_template, :boolean, default: false, null: false
  end
end
