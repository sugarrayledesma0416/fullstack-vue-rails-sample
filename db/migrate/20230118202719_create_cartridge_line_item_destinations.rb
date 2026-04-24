class CreateCartridgeLineItemDestinations < ActiveRecord::Migration[6.1]
  def change
    create_table :cartridge_line_item_destinations do |t|
      t.references :user, index: false, null: false
      t.references :section, index: false, null: false
      t.references :activity, index: false, null: false
      t.string :line_item_url, null: false

      t.timestamps

      t.index %i[user_id section_id activity_id],
        unique: true,
        name: :index_cartridge_line_item_destinations_on_user_section_activity
    end
  end
end
