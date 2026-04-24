class AddRevisionIdToMediaItem < ActiveRecord::Migration[5.2]
  def change
    add_column :media_items, :revision_id, :integer
  end
end
