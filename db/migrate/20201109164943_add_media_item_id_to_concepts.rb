class AddMediaItemIdToConcepts < ActiveRecord::Migration[5.2]
  def change
    add_column :concepts, :media_item_id, :integer
  end
end
