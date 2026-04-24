class CreateUserWords < ActiveRecord::Migration[4.2]
  def up
    create_table :user_words do |t|
      t.string    :words
      t.integer   :user_id
      t.timestamps
    end
  end

  def down
    drop_table :user_words
  end
 end
