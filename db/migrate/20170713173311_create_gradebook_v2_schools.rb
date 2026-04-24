class CreateGradebookV2Schools < ActiveRecord::Migration[4.2]
  def change
    create_table :gradebook_v2_schools do |t|
      t.integer :school_id

      t.timestamps
    end
  end
end
