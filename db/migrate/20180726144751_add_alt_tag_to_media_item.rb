class AddAltTagToMediaItem < ActiveRecord::Migration[4.2]
  def change
    add_column :media_items, :alt_tag, :string
  end
end
