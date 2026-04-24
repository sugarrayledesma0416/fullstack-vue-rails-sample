class AddSourceTemplateIdToSections < ActiveRecord::Migration[4.2]
  def change
    add_column :sections, :source_template_id, :integer, default: nil
  end
end
