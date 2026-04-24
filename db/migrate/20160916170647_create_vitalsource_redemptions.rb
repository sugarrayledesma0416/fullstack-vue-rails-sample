class CreateVitalsourceRedemptions < ActiveRecord::Migration[4.2]
  def change
    create_table :vitalsource_redemptions do |table|
      table.integer :user_id, null: false
      table.integer :program_id, null: false

      table.timestamps
    end

    add_index :vitalsource_redemptions, [:user_id, :program_id]
  end
end
