class CreateCartridgeScoreDestinations < ActiveRecord::Migration[5.2]
  def change
    create_table :cartridge_score_destinations do |t|
      t.references :user, index: false, null: false
      t.references :section, index: false, null: false
      t.references :activity, index: false, null: false
      t.string :lis_result_sourcedid, null: false

      t.timestamps

      t.index %i[user_id section_id activity_id],
        unique: true,
        name: :index_cartridge_score_destinations_on_user_section_activity
    end
  end
end
