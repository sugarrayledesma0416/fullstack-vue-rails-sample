class CreateProfile < ActiveRecord::Migration[4.2]
  def self.up
    create_table :profiles do |t|
      t.integer :user_id
      t.string :nickname
      t.string :major
      t.string :class_year
      t.string :hometown
      t.text :hobbies
      t.text :travel
      t.text :bio
      t.timestamps
    end
  end

  def self.down
    drop_table :profiles
  end
end
