class RemoveUserWordsTable < ActiveRecord::Migration[4.2]
  def up
    drop_table :user_words
  end

  def down
    create_table :user_words do |t|
      t.string    :words
      t.integer   :user_id
      t.timestamps
    end
  end
end
