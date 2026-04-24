class CreatePasscodeBatches < ActiveRecord::Migration[4.2]
  def self.up
    create_table :passcode_batches do |t|
      t.string    :name
      t.text      :comment
      t.integer   :created_by
      t.timestamps
    end
  end

  def self.down
    drop_table :passcode_batches
  end
end
