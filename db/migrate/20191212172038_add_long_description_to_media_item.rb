class AddLongDescriptionToMediaItem < ActiveRecord::Migration[5.2]
  def change
    add_column :media_items, :long_description, :text
  end
end
