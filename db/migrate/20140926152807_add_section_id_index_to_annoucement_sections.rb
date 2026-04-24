class AddSectionIdIndexToAnnoucementSections < ActiveRecord::Migration[4.2]
  def change
    add_index :announcement_sections, :section_id
  end
end
