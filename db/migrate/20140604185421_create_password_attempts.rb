class CreatePasswordAttempts < ActiveRecord::Migration[4.2]
  def change
    create_table :password_attempts do |t|
      t.integer :attempt_id
      t.string :password, :limit => 255
      t.boolean :correct

      t.timestamps
    end
    add_index :password_attempts, :attempt_id
  end
end
