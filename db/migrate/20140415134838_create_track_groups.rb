class CreateTrackGroups < ActiveRecord::Migration[4.2]
  def up
    create_table :track_groups do |t|
      t.string :name
      t.integer :program_id
      t.integer :lesson_id
      t.integer :concept_id
      t.string :how_to_use
      t.timestamps
    end
  end

  def down
    drop_table :track_groups
  end
end
