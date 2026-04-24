class AddAllowVideoPopupTranslationToCourses < ActiveRecord::Migration[4.2]
  def self.up
    add_column :courses, :allow_video_popup_translation, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :courses, :allow_video_popup_translation
  end
end
