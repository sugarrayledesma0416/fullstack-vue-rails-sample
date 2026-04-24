class AddIsEnterpriseToCourses < ActiveRecord::Migration[6.1]
  def change
    add_column :courses, :is_enterprise, :boolean, default: false
  end
end
