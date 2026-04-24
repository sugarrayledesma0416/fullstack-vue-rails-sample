class CreateAnnouncementSectionTable < ActiveRecord::Migration[4.2]
  def change
    create_table :announcement_sections do |t|
      t.integer   :announcement_id, :null => false
      t.integer   :section_id, :null => false
      t.timestamps
    end
  end
end
